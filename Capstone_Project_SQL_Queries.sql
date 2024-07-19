CREATE DATABASE Capstone_Project

USE Capstone_Project

SELECT * FROM [dbo].[Party_Data]

SELECT * FROM [DBO].[VOTES_INFO]

------------------------------------------------------------------------------------------SQL Project----------------------------------------------------------------------------------------------

--1. Create a view to join both tables to display all results(columns).

      CREATE VIEW FullElectionResults AS
      SELECT p.ID,p.State,p.Constituency,p.Candidate,p.Party,p.Result,v.EVM_Votes,v.Postal_Votes,v.Total_Votes,v.Percentage_of_Votes
      FROM Party_Data p
      JOIN Votes_Info v ON p.ID = v.ID;

	  Select * from FullElectionResults;

--2. Create a view, where the candidate won the election in their Constituency (value should be 'Yes' or 'No') along with all columns.

      CREATE VIEW Election_Results AS
      SELECT p.ID,p.State,p.Constituency,p.Candidate,p.Party,p.Result,v.EVM_Votes,v.Postal_Votes,v.Total_Votes,v.Percentage_of_Votes,
      CASE
           WHEN Result = 'Won' THEN 'Yes'
           ELSE 'No'
           END AS Winning_Candidate
           FROM Party_Data p
      JOIN Votes_Info v ON p.ID = v.ID;

       SELECT * FROM Election_Results;


--3. Find the candidate with the highest percentage of votes in each state.

      SELECT e1.State, e1.Candidate, e1.Party, e1.Percentage_of_Votes FROM FullElectionResults e1
      JOIN (
      SELECT State, MAX(Percentage_of_Votes) AS MaxPercentage FROM FullElectionResults
      GROUP BY State
      ) e2 ON e1.State = e2.State AND e1.Percentage_of_Votes = e2.MaxPercentage
      ORDER BY e1.State;


--4. List all candidates who received more than the average total votes.

        SELECT CANDIDATE, Total_Votes FROM FullElectionResults
        WHERE Total_Votes > (SELECT AVG( Total_Votes ) FROM FullElectionResults);


--5. Find the average EVM votes per state and then list all candidates who received higher than the average EVM votes in their state.

        SELECT DISTINCT(State), CANDIDATE, EVM_VOTES  FROM FullElectionResults A
        WHERE EVM_VOTES >
        (SELECT AVG(EVM_VOTES) as AVG_OF_EVM_VOTES FROM FullElectionResults B
        WHERE A.STATE = B.STATE)
        ORDER BY STATE;


--6. List pairs of candidates in the same constituency and the difference in their total votes.

        SELECT A.Candidate AS Candidate1,B.Candidate AS Candidate2, A.Total_Votes,
        ABS(A.Total_Votes - B.Total_Votes) AS VoteDifference, A.Constituency FROM FullElectionResults A
        JOIN 
        FullElectionResults B ON A.Constituency = B.Constituency AND A.Candidate <> B.Candidate;


--7. Find pairs of candidates in the same state who have similar percentages of votes (within 1% difference).

        SELECT A.Candidate AS Candidate1,B.Candidate AS Candidate2,A.State,
        ABS(A.Percentage_of_Votes - B.Percentage_of_Votes) AS Percentage_Difference FROM FullElectionResults A
        JOIN 
        FullElectionResults B ON A.State = B.State 
        WHERE A.Candidate <> b.Candidate AND ABS(A.Percentage_of_Votes - B.Percentage_of_Votes) <= 1;


--8. List pairs of candidates from the same party along with their constituencies and total votes.

        SELECT A.Candidate AS Candidate1,B.Candidate AS Candidate2, A.Constituency,A.Total_Votes AS Votes1,B.Total_Votes AS Votes2,A.Party FROM FullElectionResults A
        JOIN 
        FullElectionResults B ON A.Party = B.Party 
        WHERE A.Candidate <> B.Candidate and A.Constituency = B.Constituency;


--9. Find the candidates within the same party who have the maximum and minimum total votes in each state.
    
	    Select e1.State, e1.Party, e1.Candidate as MaxVotesCandidate, e1.Total_Votes as MaxTotalVotes from FullElectionResults e1
        Join (
        Select State, Party, Max(Total_Votes) as MaxTotalVotes from FullElectionResults
        Group by State, Party
        ) e2 on e1.State = e2.State and e1.Party = e2.Party and e1.Total_Votes = e2.MaxTotalVotes
        Order by e1.State, e1.Party;

        Select e1.State, e1.Party, e1.Candidate as MinVotesCandidate, e1.Total_Votes as MinTotalVotes from FullElectionResults e1
        Join (
        Select State,Party, Min(Total_Votes) as MinTotalVotes from FullElectionResults
        Group by State, Party
        ) e2 on e1.State = e2.State and e1.Party = e2.Party and e1.Total_Votes = e2.MinTotalVotes
        Order by e1.State, e1.Party;

--10. Find the difference in ranks between the total votes and the percentage of votes for each candidate within their constituency.

        SELECT ID,State,Constituency,Candidate,Party,Total_Votes,Percentage_of_Votes,
        RANK() OVER (PARTITION BY Constituency ORDER BY Total_Votes DESC) AS Rank_Total_Votes,
        RANK() OVER (PARTITION BY Constituency ORDER BY Percentage_of_Votes DESC) AS Rank_Percentage_of_Votes,
        RANK() OVER (PARTITION BY Constituency ORDER BY Total_Votes DESC) - 
        RANK() OVER (PARTITION BY Constituency ORDER BY Percentage_of_Votes DESC) AS Rank_Difference
        FROM FullElectionResults


--11. Find the total votes of the previous candidate within each constituency based on the total votes.

        SELECT ID,State,Constituency,Candidate,Party,Total_Votes,
        LAG(Total_Votes) OVER (PARTITION BY Constituency ORDER BY Total_Votes DESC) AS Previous_Total_Votes
        FROM FullElectionResults;


--12. Find the winning margin (difference in total votes) between the top two candidates in each constituency.

        With RankedCandidates as (
        Select p.ID,p.State,p.Constituency,p.Candidate,p.Party,v.Total_Votes,
        Rank() over (Partition by p.Constituency Order by v.Total_Votes desc) as Rank
        from Party_Data p
        Join Votes_Info v on p.ID = v.ID
      )
        Select 
        rc1.Constituency,
        rc1.Candidate as Winner,
        rc1.Total_Votes as Winner_Total_Votes,
        rc2.Candidate as Runner_Up,
        rc2.Total_Votes as Runner_Up_Total_Votes,
       (rc1.Total_Votes - rc2.Total_Votes) as Winning_Margin
        from RankedCandidates rc1
        Join RankedCandidates rc2 on rc1.Constituency = rc2.Constituency and rc2.Rank = 2
        where rc1.Rank = 1;

--13. Calculate the percentage of total votes each candidate received out of the total votes in their state and list the candidates along with their calculated percentage.

        With StateTotalVotes as (
        Select p.State,SUM(v.Total_Votes) AS Total_State_Votes from Party_Data p
        Join Votes_info v on p.ID = v.ID
        Group by p.State
      )
        Select p.State,p.Constituency,p.Candidate,p.Party,v.Total_Votes,stv.Total_State_Votes,(v.Total_Votes * 100.0 / stv.Total_State_Votes) AS Percentage_of_State_Votes
        from Party_Data p
        Join Votes_info v on p.ID = v.ID
        Join StateTotalVotes stv on p.State = stv.State;



--14. Calculate the share of total votes each candidate received out of the total votes in their state.

        SELECT State, Candidate, Total_Votes,SUM(Total_Votes) OVER (PARTITION BY State) AS State_Total_Votes,
       (ROUND((Total_Votes * 100.0 / (SELECT SUM (Total_Votes) FROM FullElectionResults B WHERE B.State = A.State)),2)) AS Vote_Share FROM FullElectionResults A;


--15. List all constituencies where the difference in total votes between the winner and the runner-up is less than 5%.


        Select e1.State, e1.Constituency, e1.Candidate as Winner, e1.Total_Votes as WinnerVotes, e2.Candidate as RunnerUp, e2.Total_Votes as RunnerUpVotes,
        ((e1.Total_Votes - e2.Total_Votes) * 100.0 / e1.Total_Votes) as VoteDifferencePercentage 
	    from (
        Select State, Constituency, Candidate, Total_Votes,
        Rank() over (Partition by State, Constituency Order by Total_Votes desc) as VoteRank
        from Election_Results
       ) e1
        Join (
        Select State, Constituency, Candidate, Total_Votes,
        Rank() over (Partition by State, Constituency Order by Total_Votes desc) as VoteRank
        from Election_Results
       ) e2 on e1.State = e2.State and e1.Constituency = e2.Constituency and e1.VoteRank = 1 and e2.VoteRank = 2
        Where ((e1.Total_Votes - e2.Total_Votes) * 100.0 / e1.Total_Votes) < 5
        Order by e1.State, e1.Constituency;
