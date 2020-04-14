# CKA preparation

## CNCF CKA official page:

https://www.cncf.io/certification/cka/

## CNCF CKA Curriculum:

https://github.com/cncf/curriculum/blob/master/CKA_Curriculum_V1.17.pdf

You will be evaluated on 10 topics around Kubernetes administation:
- [Application Lifecycle Management 8%](https://github.com/alijahnas/CKA-practice-exercises/blob/master/application-lifecycle-management.md)
- [Installation, Configuration & Validation 12%](https://github.com/alijahnas/CKA-practice-exercises/blob/master/installation-configuration-validation.md)
- [Core Concepts 19%](https://github.com/alijahnas/CKA-practice-exercises/blob/master/core-concepts.md)
- [Networking 11%](https://github.com/alijahnas/CKA-practice-exercises/blob/master/networking.md)
- [Scheduling 5%](https://github.com/alijahnas/CKA-practice-exercises/blob/master/scheduling.md)
- [Security 12%](https://github.com/alijahnas/CKA-practice-exercises/blob/master/security.md)
- [Cluster Maintenance 11%](https://github.com/alijahnas/CKA-practice-exercises/blob/master/cluster-maintenance.md)
- [Logging / Monitoring 5%](https://github.com/alijahnas/CKA-practice-exercises/blob/master/logging-monitoring.md)
- [Storage 7%](https://github.com/alijahnas/CKA-practice-exercises/blob/master/storage.md)
- [Troubleshooting 10%](https://github.com/alijahnas/CKA-practice-exercises/blob/master/troubleshooting.md)

## Useful official documentation:

- https://kubernetes.io/docs/concepts/
- https://kubernetes.io/docs/tasks/
- https://kubernetes.io/docs/reference/

## Good articles about the subject:

- https://medium.com/@pmvk/tips-to-crack-certified-kubernetes-administrator-cka-exam-c949c7a9bea1
- https://medium.com/bb-tutorials-and-thoughts/practice-enough-with-these-questions-for-the-ckad-exam-2f42d1228552
- https://github.com/stretchcloud/cka-lab-practice
- https://github.com/dgkanatsios/CKAD-exercises (Useful for CKA too)

## How it goes

The CKA is not a multiple choice question, that is, it is not possible to choose a random answer or to choose the least wrong answer. The CKA is a practical exam where you are given 24 problems to solve within 3 hours. You can go from one problem to the other and you can flag them to come back to them later if you're not sure of the answer.

We give you several clusters on which to solve the problems, and you have to be careful to be on the right cluster otherwise we don't understand why you can't find the namespaces or pods they talk about in the question, and you lose a lot of time believing that it is part of the question when it was just that you were not in the right cluster.

During the exam, you will be assessed on the 10 topics mentionned above.

So you will have to create pods, deployments, do rollouts, create a cluster with KubeADM, repair a crashing cluster, and lots of things a Kubernetes administrator does. To be comfortable with all these operations, here is what I recommend.

First, it is very useful to redo the now famous "Kubernetes the hard way" by Kelsey Hightower: https://github.com/kelseyhightower/kubernetes-the-hard-way/tree/master/docs

You can also find a similar guide from Linux Academy which explains all the steps: https://linuxacademy.com/course/kubernetes-the-hard-way/

It is not necessary to know how to do it by heart for the CKA, contrary to what we can read online. But it's good training to understand how the Kubernetes system and architecture works in detail.

Then you can repeat exercises similar to the problems you will be asked during the exam. This repo is actually a set of exercises with their solution.

I also advise you to be comfortable with using the Kubernetes official documentation: https://kubernetes.io/docs/home/ because during the exam you will not have the right to open more than one tab to do research (no Google allowed). And it is on the official documentation site that you can find lots of examples that will help you answer the problems. Besides, in the exercises that I propose above, I systematically give the link to the documentation page which allows you to respond to the problem posed. This way the search for help for the answer becomes automatic and easier during the exam and you don't have to waste too much time.

Finally, in terms of logistics. The exam takes place online, with your computer, which must have a camera for you to be monitored. Your desk on which you are taking the exam should be absolutely empty. You are entitled to a bottle of water, because it is three hours of examination. You can ask to take a break, but time does not stop during the break.

You have to be well prepared to be comfortable during the exam. If you discovered Kubernetes a month ago, it may take a lot of practice to learn all the concepts and be able to repeat them. But if you've been working on Kubernetes for more than a year, then all you have to do is to be very comfortable with templates and CLI so you don't have to be stressed by time, but the exam itself is really not difficult. You can finish it easily under two hours.

Good luck with the preparation!
