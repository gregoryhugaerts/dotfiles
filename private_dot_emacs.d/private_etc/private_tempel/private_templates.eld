org-mode
;; * workout
(workout > "** TODO Workout" n>
	 (org-timestamp-inactive) n>
	 "- [ ] 3x" p "pushup" n>
	 "- [ ] 3x" p "assisted row" n>
	 "- [ ] 3x" p "squat")
;; * GTD reviews
;; ** daily review
(dailyreview "- [ ] Clear Physical Desktop / Inbox / Notebook" n
	     "- [ ] Collect Calendar Open Loops (+/- 2  days)" n
	     "#+BEGIN_SRC emacs-lisp" n>
	     "(my/org-agenda-recent-open-loops)" n>
	     "#+END_SRC" n
	     "- [ ] Clear Email Inboxes" n>
	     "#+BEGIN_SRC emacs-lisp" n>
	     "(progn" n>
	     "(notmuch-poll)" n>
	     "(notmuch-search \"tag:inbox\"))" n>
	     "#+END_SRC" n
	     "- [ ] Process streams (rss) as inboxes - record tasks, read it later, file notes" n
	     "#+BEGIN_SRC emacs-lisp" n>
	     "(progn" n>
	     "(elfeed))" n>
	     "#+END_SRC" n
	     "- [ ] Capture any remaining open loops as tasks" n
	     "- [ ] Schedule + refile tasks" n>
	     "#+BEGIN_SRC emacs-lisp" n>
	     "(progn" n>
	     "(org-gtd-process-inbox))" n>
	     "#+END_SRC" n
	     "- [ ] Schedule today's tasks (immersive -> process, deep -> shallow):" n>
	     "#+BEGIN_SRC emacs-lisp" n>
	     "(progn" n>
	     "(org-gtd-engage))" n>
	     "#+END_SRC" n)
;; ** weekly review
(weeklyreview "*** Get Clear [0/5]" n
	      "- [ ] Collect Loose Papers and Materials" n
	      "- [ ] Get “IN” to Zero" n
	      "  - [ ] Papers" n
	      "- [ ] Physical Notebook" n
	      "  - [ ] Physical Objects" n
	      "  - [ ] Text Messages" n
	      "  - [ ] Voice Mail" n
	      "  - [ ] Email Inboxes" n
	      "#+BEGIN_SRC emacs-lisp" n>
	      "  (progn" n>
	      "    (notmuch-poll)" n>
	      "    (notmuch-search \"tag:inbox\"))" n>
	      "#+END_SRC" n
	      "  - [ ] Browser Tabs" n
	      "- [ ] Empty Your Head: New projects, tasks, waiting-fors, someday/maybes?" n
	      "*** Get Current [0/9]" n
	      "- [ ] Review Previous and Upcoming Calendar Data:" n>
	      "#+BEGIN_SRC emacs-lisp" n>
	      "(my-org-agenda-longer-open-loops)" n>
	      "#+END_SRC" n
	      "- [ ] Review Action Lists:" n
	      "#+BEGIN_SRC emacs-lisp" n
	      "  (org-gtd-engage-grouped-by-context)" n
	      "#+END_SRC" n
	      "- [ ] Review Waiting For List:" n>
	      "#+BEGIN_SRC emacs-lisp" n>
	      "  (org-gtd-review-stuck-delegated-items)" n>
	      "#+END_SRC" n
	      "- [ ] Review Project (and Larger Outcome) Lists:" n>
	      "#+BEGIN_SRC emacs-lisp" n>
	      "  (my/gtd-projects)" n>
	      "#+END_SRC" n
	      "- [ ] Review Stuck Projects:" n
	      "#+BEGIN_SRC emacs-lisp" n
	      "  (org-gtd-review-stuck-projects)" n
	      "#+END_SRC" n
	      "- [ ] Archive completed or inactive projects." n
	      "- [ ] Review Any Relevant Checklists" n
	      "*** Get Creative [0/5]" n
	      "- [ ] Review Someday/Maybe list" n>
	      "#+begin_src emacs-lisp" n>
	      "  (org-gtd-review-stuck-incubated-items" n>
	      "#+end_src" n
	      "- [ ] Be Creative and Courageous: Are there any new, wonderful, harebrained, creative, thought-provoking, risk-taking ideas you can capture and add into your system, or “external brain”?")
;; ** monthly review
(monthlyreview "*** Review [[id:5d0437dd-0f93-4164-b8c1-dc7be6b92aab][Life Goals]]" n
	       "- [ ] Scroll through completed goals." n
	       "- [ ] Move newly completed goals to “Completed” heading for archives." n
	       "- [ ] Update timelines for existing goals." n
	       "- [ ] Update wording/definition/scale of goals." n
	       "- [ ] Add any new goals, and corresponding projects if needed." n
	       "*** Review Project List" n
	       "#+BEGIN_SRC emacs-lisp" n>
	       "(project-overview)" n>
	       "#+END_SRC" n
	       "- [ ] Archive any completed or inactive projects" n
	       "- [ ] Update outcome for each project, making sure corresponding goal is listed under each project in Org-Mode" n
	       "- [ ] Order projects by general priority in Org-Mode" n
	       "*** Review Areas of Responsibility" n
	       "#+BEGIN_SRC emacs-lisp" n>
	       "  (org-gtd-review-area-of-focus)" n>
	       "#+END_SRC" n
	       "- [ ] Evaluate areas and capture any new tasks, projects, habits, routines, or decisions needed." n
	       "*** Review Someday / Maybe list" n
	       "#+begin_src emacs-lisp" n>
	       "  (org-gtd-review-stuck-incubated-items)" n>
	       "#+end_src" n
	       "- [ ] Assign next actions or new projects to any that I might want to consider doing" n
	       "*** Re-prioritize tasks" n
	       "- [ ] Review next actions and re-apply priority tags, accounting for priority drift" n
	       "*** Extract highlights from finished ebooks" n
	       "- [ ] Import text and images into [[id:030c048a-4079-4e3e-bef2-118d22422937][books]] file" n
	       "*** Extract annotations from readeck" n
	       "#+begin_src emacs-lisp" n>
	       "  (readel-annotations-buffer-render)" n>
	       "#+end_src" n
	       "- [ ] Extract into knowledge base")
;; ** yearly review
(yearlyreview "*** Write Gratitude List" n
	      "Experiences, People, Accomplishments, Learnings, Events, Circumstances, Things" n
	      "*** Answer questions about last year:" n
	      "List your 3 top wins for the year" n
	      "**** What are the biggest lessons you’ve learned this year?" n
	      "**** What were the risks you took?" n
	      "**** What was your most loving service?" n
	      "**** What is your unfinished business from this year?" n
	      "**** What are you most happy about completing?" n
	      "**** Who were the three people that had the greatest impact on your life this year?" n
	      "**** What was your biggest surprise?" n
	      "**** What compliment would you liked to have received? Given?" n
	      "**** What else do you need to do or say to be complete with this year?" n
	      "**** What one word or phrase best sums up and describes your experience this year?" n
	      "**** What stories from last year are you letting go of?" n
	      "*** Answer questions about next year:" n
	      "**** What would make 2018 your best year ever?" n
	      "**** What new habits can you cultivate that will help you to achieve your goals stated from the previous question?" n
	      "**** What bad habits can you remove that will help you to achieve your goals?" n
	      "**** What are your immediate next steps to achieve these goals?" n
	      "**** What would you like to be your biggest win?" n
	      "**** What advice would you like to give yourself?" n
	      "**** What are you planning to do to improve your financial results?" n
	      "**** What are you looking forward to learning?" n
	      "**** What do you think your biggest risk will be?" n
	      "**** Who or what, other than yourself, are you most committed to loving and serving?" n
	      "**** What about your work, are you most committed to changing and improving?" n
	      "**** What is one as yet undeveloped talent you are willing to explore?" n
	      "**** What brings you the most joy and how are you going to do or have more of that?" n
	      "**** What one word or phrase would you like to have as your theme?" n
	      "**** Set Your Intention:" n
	      "*** Add new Life Goals and Projects" n
	      "*** Read last year’s Personal Narrative Vision and write next year's" n
	      "*** Review last year’s Daily Routines and write next year's)")
