# E-Commerce Advanced Analytics & Customer Lifetime Value (CLV) Engine

An enterprise-grade relational database project designed to model a multi-vendor e-commerce platform and run complex SQL analytics queries for Business Intelligence (BI), RFM customer segmentation, and financial tracking.

## 🛠️ Tech Stack
* **Database Management System:** MySQL Workbench / MySQL
* **Advanced Concepts Applied:** CTEs (Common Table Expressions), Window Functions (`NTILE`, `SUM() OVER`, `LAG()`), Foreign Key Constraints, and Index Optimization.

## 📊 Database Schema Overview
* **Customers** (1) ──< (**Orders**) >── (N) **Order_Items** >── (1) **Products** >── (1) **Vendors**
* **Orders** (1) ──< (**Payments**)

## 🚀 Repository Contents
* **`Project - SQL.sql`**: Complete script containing table creation schemas, foreign key constraints, performance indexes, seed mock data, and advanced business intelligence analytics queries (RFM segmentation, Monthly Active Users, and Purchase Interval Analysis).
