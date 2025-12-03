// Should be placed on AI
class UGentlemanCostComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UGentlemanComponent GentComp;
	float PersonalCooldownTime;
	TArray<UObject> Claimants;
	private TArray<FGentlemanCostPendingRelease> PendingReleases;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazeActor HazeActor = Cast<AHazeActor>(Owner);
		HazeActor.JoinTeam(n"GentlemanCostTeam", UGentlemanCostTeam);
		auto TargetComp = UBasicAITargetingComponent::Get(Owner);
		TargetComp.OnChangeTarget.AddUFunction(this, n"OnChangeTarget");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		AHazeActor HazeActor = Cast<AHazeActor>(Owner);
		HazeActor.LeaveTeam(n"GentlemanCostTeam");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(int i = PendingReleases.Num()-1; i >= 0; --i)
		{
			if(!PendingReleases[i].bPending)
			{
				InternalReleaseToken(PendingReleases[i].Claimant, PendingReleases[i].GlobalCooldown, PendingReleases[i].PersonalCooldown);
				PendingReleases.RemoveAtSwap(i);
				continue;
			}
			
			PendingReleases[i].bPending = false;
		}

		if (PendingReleases.Num() == 0)
			SetComponentTickEnabled(false);
	}

	UFUNCTION()
	private void OnChangeTarget(AHazeActor NewTarget, AHazeActor OldTarget)
	{		
		if(NewTarget == nullptr)
			return;
		check(NewTarget != OldTarget);
		
		PendingReleases.Empty();
		if(GentComp != nullptr)
		{
			for(UObject Claimant: Claimants)
				GentComp.ReleaseToken(GentlemanToken::Cost, Claimant);
		}
		GentComp = UGentlemanComponent::GetOrCreate(NewTarget);
	}

	bool IsTokenAvailable(EGentlemanCost Cost)
    {
		if (Cost == EGentlemanCost::None)
			return true;
		if(GentComp == nullptr) 
			return false;
		if(Time::GameTimeSeconds < PersonalCooldownTime)
			return false;
		return GentComp.IsTokenAvailable(GentlemanToken::Cost, int(Cost));
	}

	bool IsClaimingToken(UObject Claimant)
	{
		if(GentComp == nullptr) 
			return false;
		return GentComp.IsClaimingToken(GentlemanToken::Cost, Claimant);
	}

	bool ClaimToken(UObject Claimant, EGentlemanCost Cost)
    {
		if (Cost == EGentlemanCost::None)
			return true;

		CancelPendingReleaseToken(Claimant);
		if(GentComp == nullptr) 
			return false;
		if(Time::GameTimeSeconds < PersonalCooldownTime)
			return false;
		bool Success = GentComp.ClaimToken(GentlemanToken::Cost, Claimant, int(Cost));
		if(Success)
			Claimants.AddUnique(Claimant);
		return Success;
	}

	void ReleaseToken(UObject Claimant, float GlobalCooldown = 0.0, float PersonalCooldown = 0.0)
    {
		CancelPendingReleaseToken(Claimant);
		InternalReleaseToken(Claimant, GlobalCooldown, PersonalCooldown);
	}

	private void InternalReleaseToken(UObject Claimant, float GlobalCooldown = 0.0, float PersonalCooldown = 0.0)
	{
		if(GentComp == nullptr) 
			return;
		GentComp.ReleaseToken(GentlemanToken::Cost, Claimant, GlobalCooldown);
		Claimants.RemoveSingle(Claimant);
		PersonalCooldownTime = Time::GameTimeSeconds + PersonalCooldown;
	}

	void PendingReleaseToken(UObject Claimant, float GlobalCooldown = 0.0, float PersonalCooldown = 0.0)
	{
		for(FGentlemanCostPendingRelease PendingRelease: PendingReleases)
		{
			if(PendingRelease.Claimant == Claimant)
				return;
		}

		FGentlemanCostPendingRelease PendingRelease;
		PendingRelease.Claimant = Claimant;
		PendingRelease.GlobalCooldown = GlobalCooldown;
		PendingRelease.PersonalCooldown = PersonalCooldown;
		PendingReleases.Add(PendingRelease);

		SetComponentTickEnabled(true);
	}

	void CancelPendingReleaseToken(UObject Claimant)
	{
		for(int i = PendingReleases.Num()-1; i >= 0; i--)
		{
			if(PendingReleases[i].Claimant == Claimant)
				PendingReleases.RemoveAtSwap(i);
		}
	}
}

struct FGentlemanCostPendingRelease
{
	bool bPending = true;
	UObject Claimant;
	float GlobalCooldown;
	float PersonalCooldown;
}

enum EGentlemanCost
{
	None = 0,
	XXXSmall = 1,
	XXSmall = 4,
	XSmall = 8,
	Small = 10,
	Medium = 20,
	Large = 30,
	MAX = 40
}