//Keeps track of which iteration of Ice Floor Breakage we're at, and what SmashAttackActors are valid for attack during the current iteration. 
class ATundraBossSetupBreakIceFloorManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	TArray<ATundraBossSetupSmashAttackActor> SmashAttackActors; 
	int CurrentBreakIceFloorIteration = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SmashAttackActors = TListedActors<ATundraBossSetupSmashAttackActor>().GetArray();
	}

	void ProgressBreakIceFloorIteration()
	{
		CurrentBreakIceFloorIteration++;
		RemoveInvalidSmashAttackActors();
	}

	void RemoveInvalidSmashAttackActors()
	{
		TArray<ATundraBossSetupSmashAttackActor> NewSmashAttackList;

		for(auto Actor : SmashAttackActors)
		{
			for(auto Iteration : Actor.ValidBreakIceIterations)
			{
				if (Iteration == CurrentBreakIceFloorIteration)
				{
					NewSmashAttackList.Add(Actor);
					continue;
				}
			}
		}
		SmashAttackActors = NewSmashAttackList;
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Editor")
	void PreviewIceBreakIteration(int Iteration)
	{
		TundraBossSetupIceFloor::GetIceFloor().PreviewIceIteration(Iteration);
	}

	UFUNCTION(CallInEditor, Category = "Editor")
	void UnHideIceFloorPieces()
	{
		TundraBossSetupIceFloor::GetIceFloor().UnHideIceFloorPieces();
	}
#endif
};

namespace TundraBossSetupBreakIceFloorManager
{
	UFUNCTION()
	ATundraBossSetupBreakIceFloorManager GetBreakIceFloorManager()
	{
		return TListedActors<ATundraBossSetupBreakIceFloorManager>().GetSingle();
	}
};