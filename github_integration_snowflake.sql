/*
Author: Sadrul
Linkedin: https://www.linkedin.com/in/sadrulalom
Description: Role creation and grand warehouse usage permission
*/

create database if not exists DB_GITHUB;
create schema if not exists SCH_GITHUB;

-- private repository

--display all secrets 
show secrets;

-- github secret creation
-- drop secret if exists my_github_secret;
create or replace secret my_github_secret
    type = password
    username ='sadrulemail'
    password = 'ghp_TDG4O7GZAZWUFz4cp7RhVBvWGA6MVpK31y2f0cAI1'; -- go to github setting>Developer setting> personal access tokens> toekn(classic) > generate token(classic)

-- create integration object
-- drop api integration if exists my_git_api_integration;
create or replace api integration my_git_api_integration
    api_provider = git_https_api
    api_allowed_prefixes = ('https://github.com/sadrulemail/')
    allowed_authentication_secrets = (my_github_secret)
    enabled =true;

show api integrations;
show integrations;

-- create git repo obj
create or replace git repository my_github_repo
    api_integration =  my_git_api_integration
    git_credentials = my_github_secret
    origin = 'https://github.com/sadrulemail/SF-PR';


-- public repo integration
create or replace api integration my_public_git_api_integration
    api_provider = git_https_api
    api_allowed_prefixes = ('https://github.com/sadrulemail/')
    enabled =true;

create or replace git repository my_public_github_repo
    api_integration =  my_git_api_integration
    origin = 'https://github.com/sadrulemail/SnowflakeScripts';

-- check git repo list
show git repositories;
-- list branches of a branch
show git branches in git repository my_github_repo;

-- check files of main branch
ls @my_public_github_repo/branches/main;
ls @my_github_repo/branches/main;


-- execute sql file
execute immediate from @my_public_github_repo/branches/main/Role_scripts.sql;
execute immediate from @my_github_repo/branches/main/dept.sql;

-- check git repo
desc git repository my_github_repo;

-- show tags
show git tags in git repository my_github_repo;
-- lsit all files uder a tag
ls @my_github_repo/tags/{tag_name};

-- fetch latest git repo
alter git repository my_github_repo fetch;


