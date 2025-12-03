event void FHazeTeamMemberEventSignature(AHazeActor Member);

class UHazeTeam : UObject
{
	private TArray<AHazeActor> Members;
	private TMap<FName, float> LastReportedActionTimes;
	private TArray<TSubclassOf<UHazeCapability>> PlayerCapabilities;
	private AActor Originator = nullptr;	

	FHazeTeamMemberEventSignature OnJoined;
	FHazeTeamMemberEventSignature OnLeft;

	UFUNCTION(BlueprintCallable, Category = "Team")
	void AddMember(AHazeActor TeamMember)
	{
		if (TeamMember == nullptr)
			return;

		if (!Members.Contains(TeamMember))
		{
			Members.Add(TeamMember);
			if (Originator == nullptr)
				Originator = TeamMember;

			OnMemberJoined(TeamMember);
			OnJoined.Broadcast(TeamMember);
		}
	}

	UFUNCTION(BlueprintCallable, Category = "Team")
	void RemoveMember(AHazeActor TeamMember)
	{
		if (Members.Num() > 0)
		{
			Members.Remove(TeamMember);
			OnMemberLeft(TeamMember);
			OnLeft.Broadcast(TeamMember);
		}
	}

	UFUNCTION(BlueprintCallable, Category = "Team")
	bool IsMember(AHazeActor TestMember)
	{
		return Members.Contains(TestMember);
	}

	UFUNCTION(BlueprintCallable, Category = "Team")
	void ReportAction(const FName& ActionTag)
	{
		LastReportedActionTimes.Add(ActionTag, Time::GameTimeSeconds);
	}

	UFUNCTION(BlueprintCallable, Category = "Team")
	float GetLastActionTime(const FName& ActionTag)
	{
		float Time = -BIG_NUMBER;
		LastReportedActionTimes.Find(ActionTag, Time);
		return Time;
	}

	UFUNCTION(BlueprintCallable, Category = "Team", Meta = (DisplayName="GetMembers"))
	TArray<AHazeActor> BP_GetMembers() const
	{
		return Members;
	}

	const TArray<AHazeActor>& GetMembers() const
	{
#if EDITOR
		//check(!Members.Contains(nullptr), "Team " + this.GetName() + " contains nullptr members. Call LeaveTeam before streaming out or destroying members.");
#endif
		return Members;
	}

	AActor GetOriginator() const
	{
		return Originator;
	}

	UFUNCTION(BlueprintEvent, Category = "Team")
	void OnMemberJoined(AHazeActor Member)
	{
	};

	UFUNCTION(BlueprintEvent, Category = "Team")
	void OnMemberLeft(AHazeActor Member)
	{
	};
}