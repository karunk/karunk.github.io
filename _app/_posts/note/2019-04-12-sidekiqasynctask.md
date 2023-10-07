---
layout: post
title: Sidekiq Async Task 
category: note
tags: project
desc: Making asyncronous jobs transactional・非同期ジョブをトランザクションにする! <br><br><a class="github-button" href="https://github.com/karunk/asynctask" data-icon="octicon-star" data-size="large" aria-label="Star ntkme/github-buttons on GitHub">View on Github</a>
heading-bg: img/sidekiq.png
heading-bg-local: true
heading-bg-color: "#070708"
heading-bg-size: "cover"
heading-bg-repeat: "no-repeat"
heading-bg-text: "#fff"
page.thumbnail: img/sidekiq.png
---

<!-- Place this tag in your head or just before your close body tag. -->
<script async defer src="https://buttons.github.io/buttons.js"></script>
## The Problem
 
Ever encountered a situation like this in production? 

```ruby
ActiveRecord::Base.transaction do
  user_one.process_action_one
  user_two.process_action_two
  MailWorker.perform_async("UserMailer", "success_mail", user_one.id)
  MailWorker.perform_async("UserMailer", "success_mail", user_two.id)
end
```
Where we have to process a group of actions within a transaction, and on success send mails to users.
We use asycronous jobs to send our mails, as it can be blocking if done otherwise. 


Everything seems fine and simple, but what happens if during the function calls, an error is raised and the transaction which encapsulates these lines of code is rolled back? 

Since the jobs are already scheduled to run asyncronously, they will be processed regardless of the success or failure of the transaction. This can cause a problem, because the users could receive an erroneous notification if the transaction had rolled back and the intended code not executed.

We thus require, a solution which only schedules asyncronous jobs called within a transaction, **to be processed once the encapsulating transaction commits**. 


## The Solution

[Sidekiq Async Task](https://rubygems.org/gems/sidekiq_async_task) solves exactly this problem.
This is a **ruby gem** which gives your **Sidekiq** background workers the feature to be *transaction-safe*. That is, it guarentees that the asyncronous sidekiq jobs within a transaction will only be executed once the transaction commits.


## The Usage


- **Install the gem**, run the gem generators and migrate your database. (This gem adds a model in your database which keeps track of what asyncronous task to execute when).
```sh
$ gem sidekiq_async_task #Add to gemspec
$ bundle install
$ rails generate sidekiq_async_task:install
$ rake db:migrate
```
- **Inherit** ``SidekiqAsyncTask::TransactionSupport`` to your *Sidekiq* worker.

```ruby
class MailWorker < SidekiqAsyncTask::TransactionSupport
  include Sidekiq::Worker
  sidekiq_options retry: true

  def perform_with_callback(*args)
    #Logic for sending mail
  end

end
```

- **Define** your worker logic in the `perform_with_callback` method instead of the generic `perform` method, in the worker class.

- **Schedule** your asyncronous tasks using any of these interfaces.

```ruby
HardWorker.perform_with_transaction_in(1.second, args)
HardWorker.perform_with_transaction_at(time, args)
HardWorker.perform_with_transaction_async(args)
HardWorker.perform_with_transaction_future(time, args)
```

- **Enjoy** safe transactional asyncronous tasks in rails!


## The Working

Everytime we ask Sidekiq to run a worker asyncronously, the gem **creates an entry in the AsyncTask table in the database**. When the transaction commits, the AsyncTask entry also commits. The gem defines logic in the **after_commit callback** of the AsyncTask model to process the job corresponding to the AsyncTask entry.

We can also create an [active_admin](https://activeadmin.info/) dashboard for this model to have a UI to view all the scheduled and processed AsyncTasks in our database. 