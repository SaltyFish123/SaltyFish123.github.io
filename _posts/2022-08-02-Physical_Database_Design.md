---
layout: post
title: "#16 Physical Database Design and Tuning"
date: 2022-08-02
categories: SQL
tags: DBMS
---

* TOC
{:toc}

The perfomance of a DBNS on commonly asked queries and typical update operations is the ultimate measure of a database design. A DBA can improve performance by identifying performance bottlenecks and adjusting some DBMS parameters (e.g., the size of the buffer pool or the frequency of checkpointing) or adding hardware to eliminate such bottlenecks. The first step in achieving good performance, however, is to make good database design choices, which is the focus of this chapter. After we design the conceptual and external schemas, that is, create a collection of relations and views along with a set of integrity constraints, we must address performance goals through physical database design, in which we design the physical schema. As user requirements evolve, it is usually necessary to tune, or adjust, all aspects of a database design for good perforrnance.

## Introduction to Physical Database Design

Like all other aspects of database design, physical design must be guided by the nature of the data and its intended use. In particular, it is important to understand the typical **workload** that the database must support; the workload consists of a mix of queries and updates. Users also have certain requirements about how fast certain queries or updates must run or how many transactions must be processed per second. The workload description and users' performance requirements are the basis on which a number of decisions have to be made during physical database design.

### Database Workloads

The key to good physical design is arriving at an accurate description of the expected workload. A **workload** description includes the following:

1. A list of queries (with their frequency, as a ratio of all queries/updates).
2. A list of updates and their frequencies.
3. Performance goals for each type of query and update.

For each query in the workload, we must identify

* Which relations are accessed.
* Which attributes are retained(in the select clause).
* Which attributes have selection of join conditions expressed on them (in the WHERE clause) and how selective these conditions are likely to be.

Similarly, for each update in the workload, we must identify

* Which attributes have selection or join conditions expressed on them (in the WHERE clause) and how selective these conditions are likely to be.
* The type of update (INSERT, DELETE, or UPDATE) and the updated relation.
* For UPDATE commands, the fields that are modified by the update.

## Guidelines for Index Selection

The following guidelines for index selection summarize our discussion:

Whether to Index (Guideline 1): The obvious points are often the most important. Do not build an index unless some query including the query components of updates benefits from it. Whenever possible, choose indexes that speed up more than one query.

Choice of Search Key (Guideline 2): Attributes mentioned in a WHERE clause are candidates for indexing.

* An exact-match selection condition suggests that we consider an index on the selected attributes, ideally, a hash index.
* A range selection condition suggests that we consider a B+ tree (or ISAM) index on the selected attributes. A B+ tree index is usually preferable to an ISAM index. An ISAM index may be worth considering if the relation is infrequently updated, but we assume that a B+ tree index is always chosen over an ISAM index, for simplicity.

Multi-Attribute Search Keys (Guideline 3): Indexes with multiple-attribute search keys should be considered in the following two situations:

* A WHERE clause includes conditinns on more than one attribute of a relation.
* They enable index-only evaluation strategies (i.e., accessing the relation can be avoided) for important queries. (This situation could lead to attributes being in the search key even if they do not appear in WHERE clauses.)

When creating indexes on search keys with multiple attributes, if range queries axe expected, be careful to order the attributes in the search key to match the queries.

Whether to Cluster (Guideline 4): At most one index on a given relation can be clustered, and clustering affects performance greatly; so the choice of clustered index is important.

* As a rule of thunb, range queries are likely to benefit the most from clustering. If several range queries are posed on a relation, involving different sets of attributes, consider the selectivity of the queries and their relative frequency in the workload when deciding which index should be clustered.
* **If an index enables an index-only evaluation strategy for the query it is intended to speed up, the index need not be clustered. (Clustering matters only when the index is used to retrieve tuples from the underlying relation.)**

Hash versus Tree Index (Guideline 5): A B+ tree index is usually preferable because it supports range queries as well as equality queries. A hash index is better in the following situations:

* The index is intended to support index nested loops join; the indexed relation is the inner relation, and the search key includes the join columns. In this case, the slight improvement of a hash index over a B+ tree for equality selections is magnified, because an equality selection is generated for each tuple in the outer relation.
* There is a very important equality query, and no range queries, involving the search key attributes.

Balancing the Cost of Index Maintenance (Guideline 6): After drawing up a wishlist of indexes to create, consider the impact of each index on the updates in the workload.

* If maintaining an index slows down frequent update operations, consider dropping the index.
* Keep in mind, however, that adding an index may well speed up a given update operation. For example, an index on employee IDs could speed up the operation of increasing the salary of a given employee (specified by ID).

### Clustering and Indexing

When we retrieve tuples using an index, the impact of clustering depends on the number of retrieved tuples, that is, the number of tuples that satisfy the selection conditions that match the index. An unclustered index is just as good as clustered index for a selection that retrieves a single tuple (e.g., an equality selection on a candidate key). As the number of retrieved tuples increases, the unclustered index quickly becomes more expensive than even a sequential scan of the entire relation. Although the sequential scan retrieves all tuples, each page is retrieved exactly once, whereas a page may be retrieved as often as the number of tuples it contains if an unclustered index is use. If blocked I/O is performed (as is common), the relative advantage of sequential scan versus an unclustered index increases further. We illustrate the relationship between the number of retrieved tuples, viewed as a percentage of the total number of tuples in the relation, and the cost of various access methods in Figure 20.2. We assume that the query is a selection on a single relation, for simplicity. (Note that this figure reflects the cost of writing out the result: otherwise the line for seqnential scan would be flat.)

![figure 20.2](https://github.com/SaltyFish123/SaltyFish123.github.io/blob/master/assets/images/SQL/figure_20_2.png?raw=true)
