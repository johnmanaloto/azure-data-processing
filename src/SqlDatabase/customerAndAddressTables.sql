/****** Object:  Table [SalesLT].[Address]    Script Date: 5/25/2017 9:21:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'SalesLT')
begin 
	exec('create schema SalesLT')
end
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SalesLT].[Address]') AND type in (N'U'))
BEGIN
	CREATE TABLE [SalesLT].[Address](
		[AddressID] [int] IDENTITY(1,1) NOT NULL,
		[AddressLine1] [nvarchar](60) NOT NULL,
		[AddressLine2] [nvarchar](60) NULL,
		[City] [nvarchar](30) NOT NULL,
		[StateProvince] [nvarchar](50) NOT NULL,
		[CountryRegion] [nvarchar](50) NOT NULL,
		[PostalCode] [nvarchar](15) NOT NULL,
		[rowguid] [uniqueidentifier] NOT NULL,
		[ModifiedDate] [datetime] NOT NULL,
	 CONSTRAINT [PK_Address_AddressID] PRIMARY KEY CLUSTERED 
	(
		[AddressID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON),
	 CONSTRAINT [AK_Address_rowguid] UNIQUE NONCLUSTERED 
	(
		[rowguid] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	)
END
GO
/****** Object:  Table [SalesLT].[Customer]    Script Date: 5/25/2017 9:21:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SalesLT].[Customer]') AND type in (N'U'))
BEGIN
	CREATE TABLE [SalesLT].[Customer](
		[CustomerID] [int] IDENTITY(1,1) NOT NULL,
		[NameStyle] bit NOT NULL,
		[Title] [nvarchar](8) NULL,
		[FirstName] [nvarchar](50) NOT NULL,
		[MiddleName] [nvarchar](50) NULL,
		[LastName] [nvarchar](50) NOT NULL,
		[Suffix] [nvarchar](10) NULL,
		[CompanyName] [nvarchar](128) NULL,
		[SalesPerson] [nvarchar](256) NULL,
		[EmailAddress] [nvarchar](50) NULL,
		[Phone] [nvarchar](25) NULL,
		[PasswordHash] [varchar](128) NOT NULL,
		[PasswordSalt] [varchar](10) NOT NULL,
		[rowguid] [uniqueidentifier] NOT NULL,
		[ModifiedDate] [datetime] NOT NULL,
	 CONSTRAINT [PK_Customer_CustomerID] PRIMARY KEY CLUSTERED 
	(
		[CustomerID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON),
	 CONSTRAINT [AK_Customer_rowguid] UNIQUE NONCLUSTERED 
	(
		[rowguid] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	)
END
GO
/****** Object:  Table [SalesLT].[CustomerAddress]    Script Date: 5/25/2017 9:21:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SalesLT].[CustomerAddress]') AND type in (N'U'))
BEGIN
CREATE TABLE [SalesLT].[CustomerAddress](
	[CustomerID] [int] NOT NULL,
	[AddressID] [int] NOT NULL,
	[AddressType] [nvarchar](50) NOT NULL,
	[rowguid] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_CustomerAddress_CustomerID_AddressID] PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC,
	[AddressID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON),
 CONSTRAINT [AK_CustomerAddress_rowguid] UNIQUE NONCLUSTERED 
(
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
end
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SalesLT].[CustomerAddress]') AND type in (N'U'))
BEGIN
ALTER TABLE [SalesLT].[CustomerAddress] ADD  CONSTRAINT [DF_CustomerAddress_rowguid]  DEFAULT (newid()) FOR [rowguid]
ALTER TABLE [SalesLT].[CustomerAddress] ADD  CONSTRAINT [DF_CustomerAddress_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
ALTER TABLE [SalesLT].[CustomerAddress]  WITH CHECK ADD  CONSTRAINT [FK_CustomerAddress_Address_AddressID] FOREIGN KEY([AddressID])
REFERENCES [SalesLT].[Address] ([AddressID])
ALTER TABLE [SalesLT].[CustomerAddress] CHECK CONSTRAINT [FK_CustomerAddress_Address_AddressID]
ALTER TABLE [SalesLT].[CustomerAddress]  WITH CHECK ADD  CONSTRAINT [FK_CustomerAddress_Customer_CustomerID] FOREIGN KEY([CustomerID])
REFERENCES [SalesLT].[Customer] ([CustomerID])
ALTER TABLE [SalesLT].[CustomerAddress] CHECK CONSTRAINT [FK_CustomerAddress_Customer_CustomerID]
END