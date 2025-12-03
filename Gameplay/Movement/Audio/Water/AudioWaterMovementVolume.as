
enum EHazeAudioWaterMovementType
{
	Slide,
	Footsteps,
}

struct FAudioWaterMovementState
{
	EHazeAudioWaterMovementType PreviousState;
	UPlayerSlideComponent SlideComponent = nullptr;
	bool bInOverlap = false;
}

class AAudioWaterMovementVolume : AVolume
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

	UPROPERTY(VisibleAnywhere)
	FVector SurfacePosition;

	TPerPlayer<FAudioWaterMovementState> DataByPlayer;

	UFUNCTION(BlueprintOverride)
    private void ActorBeginOverlap(AActor OtherActor)
    {		
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		
		auto& Data = DataByPlayer[Player];
		Data.SlideComponent = UPlayerSlideComponent::Get(Player);
		Data.bInOverlap = true;
		Data.PreviousState = Data.SlideComponent != nullptr && Data.SlideComponent.IsSlideActive() ? EHazeAudioWaterMovementType::Slide : EHazeAudioWaterMovementType::Footsteps;
		TriggerOverlapEnterEvent(Player, Data.PreviousState);
		
		if (!IsActorTickEnabled())
			SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
    private void ActorEndOverlap(AActor OtherActor)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		
		auto& Data = DataByPlayer[Player];
		Data.bInOverlap = false;
		TriggerOverlapExitEvent(Player, Data.PreviousState);
		Data.SlideComponent = nullptr;
	}

	// Only relevant for footsteps.
	UFUNCTION(BlueprintPure)
	float GetWaterDepth(const FVector& InPosition)
	{
		auto Result = SurfacePosition.Z - InPosition.Z;
		if (Result < 0)
			return 0;

		return Result;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bOverlapping = false;
		for (auto& Data : DataByPlayer)
		{
			if (Data.bInOverlap == false)
				continue;
			
			bOverlapping = true;
			EHazeAudioWaterMovementType CurrentState = Data.SlideComponent.IsSlideActive() ? EHazeAudioWaterMovementType::Slide : EHazeAudioWaterMovementType::Footsteps;

			if (bOverlapping && Data.PreviousState != CurrentState)
			{
				if (bOverlapping)
				{
					TriggerOverlapExitEvent(Data.SlideComponent.Player, Data.PreviousState);
					TriggerOverlapEnterEvent(Data.SlideComponent.Player, CurrentState);
				}

				Data.PreviousState = CurrentState;
			}
		}

		if (!bOverlapping)
			SetActorTickEnabled(false);
	}

	void TriggerOverlapEnterEvent(AHazePlayerCharacter Player, const EHazeAudioWaterMovementType& InType)
	{
		switch(InType)
		{
			case EHazeAudioWaterMovementType::Slide:
			UAudioWaterMovementVolumeEventHandler::Trigger_OnSlideEnterWater(Player, FHazeAudioWaterMovementVolumeData(this));
			UPlayerCoreMovementEffectHandler::Trigger_Slide_Start_Water(Player);
			break;
			case EHazeAudioWaterMovementType::Footsteps:
			UAudioWaterMovementVolumeEventHandler::Trigger_OnFootstepsEnterWater(Player, FHazeAudioWaterMovementVolumeData(this));
			break;
		}
	}

	void TriggerOverlapExitEvent(AHazePlayerCharacter Player, const EHazeAudioWaterMovementType& InType)
	{
		switch(InType)
		{
			case EHazeAudioWaterMovementType::Slide:
			UAudioWaterMovementVolumeEventHandler::Trigger_OnSlideExitWater(Player, FHazeAudioWaterMovementVolumeData(this));
			UPlayerCoreMovementEffectHandler::Trigger_Slide_Stop_Water(Player);
			break;
			case EHazeAudioWaterMovementType::Footsteps:
			UAudioWaterMovementVolumeEventHandler::Trigger_OnFootstepsExitWater(Player, FHazeAudioWaterMovementVolumeData(this));
			break;
		}
	}
}