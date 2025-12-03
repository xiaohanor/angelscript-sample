enum EDesertPlayerCrankState
{
	Enter,
	Cranking,
	Exit
}

struct FDesertPlayerCrankData
{
	UPROPERTY()
	bool bIsCrankingRightSide = false;

	UPROPERTY()
	EDesertPlayerCrankState State;

	// Buttonmash progress from both players, normalized 0:1 value
	UPROPERTY()
	float CrankProgress = 0.0;
}

class UDesertPlayerCrankComponent : UActorComponent
{
	default TickGroup = ETickingGroup::TG_PrePhysics;

	UPROPERTY()
	UHazeLocomotionFeatureBase FeatureBase;

	FDesertPlayerCrankData CrankData;

	AHazePlayerCharacter Player;
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	void AddLocomotionFeature(UObject Instigator)
	{
		CrankData.State = EDesertPlayerCrankState::Enter;
		Player.AddLocomotionFeature(FeatureBase, Instigator);
	}

	void RemoveLocomotionFeature(UObject Instigator)
	{
		Player.RemoveLocomotionFeature(FeatureBase, Instigator);
	}

	void RequestLocomotion(bool bIsRightSideCrank, FInstigator Instigator)
	{
		if (Player.Mesh.CanRequestLocomotion())
		{
			CrankData.bIsCrankingRightSide = bIsRightSideCrank;
			Player.Mesh.RequestLocomotion(n"Crank", Instigator);
		}
	}

	void StartCranking()
	{
		CrankData.State = EDesertPlayerCrankState::Cranking;
	}

	void StopCranking()
	{
		CrankData.State = EDesertPlayerCrankState::Exit;
	}
};