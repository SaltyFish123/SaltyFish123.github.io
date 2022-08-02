---
layout: post
title: "#6 Description of SQL"
date: 2022-07-18
categories: SQL
tags: DBMS
---

* TOC
{:toc}

## SQL: Queries, Constraints, Triggers

The Structured Query Language(SQL) has several aspects to it.

* The Data Manipulation Language (DML): This subset of SQL allows users to pose queries and to insert, delete, and modify rows.
* The Data Definition Language (DDL): This subset of SQL supports the creation, deletion, and modification of definitions for tables and views. Integrity constraints can be defined on tables, either when the table is created or later.
* Triggers and Advanced Integrity Constraints: The new SQL:1999 standard includes support for triggers, which are actions executed by the DBMS whenever changes to the database meet conditions specified in the trigger.
* Embedded and Dynamic SQL: Embedded SQL features allow SQL code to be called from a host language such as C. Dynamic SQL features allow a query to be constructed (and executed) at run-time.
* Client-Server Execution and Remote Database Access: These commands control how a client application program can connect to an SQL database server, or access data from a database over a network.
* Transaction Management: Various commands allow a user to explicitly control aspects of how a transaction is to be executed.
* Security: SQL provides mechanisms to control users' access to data objects such as tables and views.

We will present a number of sample queries using the following table definitions:

```sql
Sailors( sid: integer, sname: string, rating: integer, age: real)
Boats( bid: integer, bname: string, color: string)
Reserves ( sid: integer, bid: integer, day: date)
```

![figure 5.1](https://github.com/SaltyFish123/SaltyFish123.github.io/blob/master/assets/images/SQL/figure_5_1.png?raw=true)

### The Form of a Basic SQL Query

This section presents the syntax of a simple SQL query and explains its meaning through a conceptual Evaluation strategy. A conceptual evaluation strategy is a way to evaluate the query that is intended to be easy to understand rather than efficient. A DBMS would typically execute a query in a different and more efficient way.

The basic form of an SQL query is as follows:

```sql
SELECT [DISTINCT] select-list
FROM from-list
WHERE qualification
```

Every query must have a SELECT clause, which specifies columns to be retained in the result, and a FROM clause, which specifies a cross-product of tables. The optional WHERE clause specifies selection conditions on the tables mentioned in the FROM clause.

A multiset is similar to a set in that it is an unordered collection of elements, but there could be several copies of each element, and the number of copies is significant-two multisets could have the same elements and yet be different because the number of copies is different for some elements. For example, {a, b, b} and {b, a, b} denote the same multiset, and differ from the multiset {a, a, b}.

### Nested Queries

One of the most powerful features of SQL is nested queries. A nested query is a query that has another query embedded within it; the embedded query is called a subquery.

### Outer Joins

Some interesting variants of the join operation that rely on null values, called **outer joins**, are supported in SQL. Consider the join of two tables, say Sailors $\bowtie_c$ Reserves. Tuples of Sailors that do not match some row in Reserves according to the join condition c do not appear in the result. In an outer join, on the other hand, Sailor rows without a matching Reserves row appear exactly once in the result, with the result columns inherited from Reserves assigned null values.

In fact, there are several variants of the outer join idea. In a **left outer join**, Sailor rows without a matching Reserves row appear in the result, but not vice versa. In a **right outer join**, Reserves rows without a matching Sailors row appear in the result, but not vice versa. In a **full outer join**, both Sailors and Reserves rows without a match appear in the result. (Of course, rows with a match always appear in the result, for all these variants, just like the **usual joins**, sometimes called **inner joins**)

### Triggers and Active DataBases

A trigger is a procedure that is automatically invoked by the DBMS in response to specified changes to the database, and is typically specified by the DBA. A database that has a set of associated triggers is called an active database. A trigger description contains three parts:

* **Event**: A change to the database that activates the trigger.
* **Condition**: A query or test that is run when the trigger is activated.
* **Action**: A procedure that is executed when the trigger is activated and its condition is true.

A trigger can be thought of as a 'daemon' that monitors a database, and is executed when the database is modified in a way that matches the event specification. An insert, delete, or update statement could activate a trigger, regardless of which user or application invoked the activating statement; users may not even be aware that a trigger was executed as a side effect of their program.

### Designing Active Databases

Triggers offer a powerful mechanism for dealing with changes to a database, but they must be used with caution. The effect of a collection of triggers can be very complex, and maintaining an active database can become very difficult. Often, a judicious use of integrity constraints can replace the use of triggers.

In an active database system, when the DBMS is about to execute a statement that modifies the database, it checks whether some trigger is activated by the statement. If so, the DBMS processes the trigger by evaluating its condition part, and then (if the condition evaluates to true) executing its action part. If a statement activates more than one trigger, the DBMS typically processes all of them, in some arbitrary order. An important point is that the execution of the action part of a trigger could in turn activate another trigger. In particular, the execution of the action part of a trigger could again activate the same trigger; such triggers are called recursive triggers. The potential for such chain activations and the unpredictable order in which a DBMS processes activated triggers can make it difficult to understand the effect of a collection of triggers.

A common use of triggers is to maintain database consistency, and in such cases, we should always consider whether using an integrity constraint (e.g., a foreign key constraint) achieves the same goals. The meaning of a constraint is not defined operationally, unlike the effect of a trigger. This property makes a constraint easier to understand, and also gives the DBMS more opportunities to optimize execution. A constraint also prevents the data from being made inconsistent by any kind of statement, whereas a trigger is activated by a specific kind of statement (INSERT, DELETE, or UPDATE). Again, this restriction makes a constraint easier to understand.
