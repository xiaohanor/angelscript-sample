
/** This component takes care of hiding the actor when scrubbing the temporal log */
class UTemporalLogScrubbableVisible : UHazeTemporalLogScrubbableComponent
{
	default PrimaryComponentTick.bTickEvenWhenPaused = true;

	bool bHasBlockedVisible = false;
	bool bIsPlayer = false;
	AHazeActor HazeOwner;
	TArray<AActor> BlockVisibilityActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		bIsPlayer = HazeOwner.IsA(AHazePlayerCharacter);
	}

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogScrubbedToFrame(UHazeTemporalLog Log, int LogFrameNumber)
	{
		if(!bHasBlockedVisible && HazeOwner != nullptr)
		{
			if(bIsPlayer)
			{
				HazeOwner.BlockCapabilities(CapabilityTags::Visibility, this);
				HazeOwner.GetAttachedActors(BlockVisibilityActors);
				BlockVisibilityActors.Add(HazeOwner.GetAttachParentActor());
				for(auto Actor : BlockVisibilityActors)
				{
					if(Actor == nullptr)
						continue;

					if(Actor.IsA(AHazePlayerCharacter))
						continue;

					if(Actor.IsA(AHazeWorldSettings))
						continue;

					Actor.AddActorVisualsBlock(this);
				}
			}
			else
			{
				HazeOwner.AddActorVisualsBlock(this);
			}
			
			bHasBlockedVisible = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogStopScrubbing(UHazeTemporalLog Log)
	{
		if(bHasBlockedVisible && HazeOwner != nullptr)
		{
			if(bIsPlayer)
			{
				HazeOwner.UnblockCapabilities(CapabilityTags::Visibility, this);
				for(auto Actor : BlockVisibilityActors)
				{
					if(Actor == nullptr)
						continue;

					if(Actor.IsA(AHazePlayerCharacter))
						continue;

					Actor.RemoveActorVisualsBlock(this);
				}

				BlockVisibilityActors.Reset();	
			}
			else
			{
				HazeOwner.RemoveActorVisualsBlock(this);
			}
			bHasBlockedVisible = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bHasBlockedVisible && HazeOwner != nullptr)
		{
			Debug::DrawDebugBox(HazeOwner.GetActorCenterLocation(), HazeOwner.GetActorBoxExtents(true) * 3.0, HazeOwner.GetActorRotation(), Thickness = 1.0);
		}
	}

}
