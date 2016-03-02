
// Copyright(c) 2011 IndiaNIC.com. All rights reserved.

#import "Database.h"


static Database *shareDatabase =nil;

@implementation Database
#pragma mark -
#pragma mark Database


+(Database*) shareDatabase
{
	
	if(!shareDatabase)
    {
		shareDatabase = [[Database alloc] init];
	}
	
	return shareDatabase;
}

#pragma mark -
#pragma mark Get DataBase Pathd
NSString * const DataBaseName  = @"Courier.sqlite"; // Pass Your DataBase Name Over here

- (NSString *) GetDatabasePath:(NSString *)dbName
{
	NSArray  *paths        = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
	NSString *documentsDir = [paths objectAtIndex:0];
    
    // Check if the database file exists in the documents directory.
    NSString *destinationPath = [documentsDir stringByAppendingPathComponent:DataBaseName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath])
    {
        // The database file does not exist in the documents directory, so copy it from the main bundle now.
        NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DataBaseName];
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error];
        
        // Check if any error occurred during copying and display it.
        if (error != nil) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }

    
	return [documentsDir stringByAppendingPathComponent:dbName];
    
    
  
         }

    


//-(BOOL) createEditableCopyOfDatabaseIfNeeded
//{
//    BOOL success; 
//    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSError *error;
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:DataBaseName];
//    
//    success = [fileManager fileExistsAtPath:writableDBPath];
//    if (success) return success;
//    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DataBaseName];
//    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
//    // add donot backup code
//   // [[NSFileManager defaultManager] addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:defaultDBPath]];
//    
//    if (!success) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!!!" message:@"Failed to create writable database" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
//        [alert show];
//        //[alert release];
//        }
//    return success;
//}


#pragma mark -
#pragma mark Get All Record

-(NSMutableArray *)SelectAllFromTable:(NSString *)query
{
	sqlite3_stmt *statement = nil ;
	NSString *path = [self GetDatabasePath:DataBaseName];
	
	NSMutableArray *alldata;
	alldata = [[NSMutableArray alloc] init];
	int temp = 0;
	if(sqlite3_open([path UTF8String],&databaseObj) == SQLITE_OK )
	{
    
		if((sqlite3_prepare_v2(databaseObj,[query UTF8String],-1, &statement, NULL)) == temp)
		{
			while(sqlite3_step(statement) == SQLITE_ROW)
			{	
				NSMutableDictionary *currentRow = [[NSMutableDictionary alloc] init];
                
				int count = sqlite3_column_count(statement);
				
				for (int i=0; i < count; i++) {
                    
					char *name = (char*) sqlite3_column_name(statement, i);
					char *data = (char*) sqlite3_column_text(statement, i);
					
					NSString *columnData;   
					NSString *columnName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
                    
					if(data != nil){
						columnData = [NSString stringWithCString:data encoding:NSUTF8StringEncoding];
					}else {
						columnData = @"";
					}
                    
					[currentRow setObject:columnData forKey:columnName];
				}
                
				[alldata addObject:currentRow];
                //[currentRow release];
			}
		}
		sqlite3_finalize(statement); 
	}
	sqlite3_close(databaseObj) ;
//       == SQLITE_OK){
//    
//    }
//    else
//    {
//          //  NSAssert1(0, @"Error: failed to close database on memwarning with message '%s'.", sqlite3_errmsg(databaseObj));
//    }
    NSMutableArray *ary = [NSMutableArray arrayWithArray:alldata];
    //[alldata release];
	return ary;

}

#pragma mark -
#pragma mark Get Record Count

-(int)getCount:(NSString *)query
{
	int m_count=0;
	sqlite3_stmt *statement = nil ;
	NSString *path = [self GetDatabasePath:DataBaseName] ;
	
	if(sqlite3_open([path UTF8String],&databaseObj) == SQLITE_OK )
	{
		if((sqlite3_prepare_v2(databaseObj,[query UTF8String],-1, &statement, NULL)) == SQLITE_OK)
		{
			if(sqlite3_step(statement) == SQLITE_ROW)
			{	
				m_count= sqlite3_column_int(statement,0);
			}
		}
		sqlite3_finalize(statement); 
	}
    sqlite3_close(databaseObj);
	return m_count;
}

#pragma mark -
#pragma mark Check For Record Present

-(BOOL)CheckForRecord:(NSString *)query
{	
	sqlite3_stmt *statement = nil;
	NSString *path = [self GetDatabasePath:DataBaseName];
	int isRecordPresent = 0;
		
	if(sqlite3_open([path UTF8String],&databaseObj) == SQLITE_OK )
	{
		if((sqlite3_prepare_v2(databaseObj, [query UTF8String], -1, &statement, NULL)) == SQLITE_OK)
		{
			if(sqlite3_step(statement) == SQLITE_ROW)
			{
				isRecordPresent = 1;
			}
			else {
				isRecordPresent = 0;
			}
		}
	}
	sqlite3_finalize(statement);	
	if(sqlite3_close(databaseObj) == SQLITE_OK){
        
    }else{
        NSAssert1(0, @"Error: failed to close database on memwarning with message '%s'.", sqlite3_errmsg(databaseObj));
    }	
	return isRecordPresent;
}

#pragma mark -
#pragma mark Insert

- (void)Insert:(NSString *)query 
{	
	sqlite3_stmt *statement=nil;
	NSString *path = [self GetDatabasePath:DataBaseName];
	
	if(sqlite3_open([path UTF8String],&databaseObj) == SQLITE_OK)
	{
		if((sqlite3_prepare_v2(databaseObj, [query UTF8String], -1, &statement,NULL)) == SQLITE_OK)
		{
			sqlite3_step(statement);
		}
	}
	sqlite3_finalize(statement);
	if(sqlite3_close(databaseObj) == SQLITE_OK){
        
    }else{
        NSAssert1(0, @"Error: failed to close database on memwarning with message '%s'.", sqlite3_errmsg(databaseObj));
    }
}

#pragma mark -
#pragma mark DeleteRecord

-(void)Delete:(NSString *)query
{
	sqlite3_stmt *statement = nil;
	NSString *path = [self GetDatabasePath:DataBaseName] ;
	if(sqlite3_open([path UTF8String],&databaseObj) == SQLITE_OK )
	{
		if((sqlite3_prepare_v2(databaseObj, [query UTF8String], -1, &statement, NULL)) == SQLITE_OK)
		{
			sqlite3_step(statement);
		}
	}
	sqlite3_finalize(statement);
	if(sqlite3_close(databaseObj) == SQLITE_OK){
        
    }
    else
    {
        NSAssert1(0, @"Error: failed to close database on memwarning with message '%s'.", sqlite3_errmsg(databaseObj));
    }
}

#pragma mark -
#pragma mark UpdateRecord

-(void)Update:(NSString *)query
{
	sqlite3_stmt *statement=nil;
	NSString *path = [self GetDatabasePath:DataBaseName] ;
	
	if(sqlite3_open([path UTF8String],&databaseObj) == SQLITE_OK)
	{
		if(sqlite3_prepare_v2(databaseObj, [query UTF8String], -1, &statement, NULL) == SQLITE_OK)
		{
			sqlite3_step(statement);
		}
		sqlite3_finalize(statement);
	}
	sqlite3_close(databaseObj);
}

@end
