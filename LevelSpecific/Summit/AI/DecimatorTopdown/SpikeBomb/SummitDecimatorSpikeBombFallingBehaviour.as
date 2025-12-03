// Blocks other behaviour in selector
class USummitDecimatorSpikeBombFallingBehaviour : UBasicBehaviour
{
	//default Requirements.
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Perception);

	USummitMeltComponent MeltComp;
	UHazeMovementComponent MoveComp;
	UHazeActorRespawnableComponent RespawnComp;
	UHazeOffsetComponent MeshOffsetComponent;
	
	FVector OriginalScale;
	float CurrentScaleFactor;
	bool bHasLanded = false;
	float AirTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MeltComp = USummitMeltComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"Reset");
		MeshOffsetComponent = Cast<AAISummitDecimatorSpikeBomb>(Owner).MeshOffsetComponent;
		OriginalScale = MeshOffsetComponent.GetWorldScale();
	}

	UFUNCTION()
	private void Reset()
	{
		bHasLanded = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (MoveComp.IsOnAnyGround())
			return false;

		if (bHasLanded && AirTime < 0.1)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{		
		if (Super::ShouldDeactivate())
			return true;
		
		if (MoveComp.IsOnAnyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		CurrentScaleFactor = 0.4;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (!bHasLanded)
		{
			USummitDecimatorSpikeBombEffectsHandler::Trigger_OnLandedAfterSpawn(Owner);		
			bHasLanded = true;
		}
		else
		{
			USummitDecimatorSpikeBombEffectsHandler::Trigger_OnLanded(Owner);
		}
		MeshOffsetComponent.SetWorldScale3D(OriginalScale);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bHasLanded)
			return;
		
		CurrentScaleFactor += DeltaTime * 0.6 * 2.0; // scale: 0.4->1.0 in t: 1 / 2.0 = 0.5s.
		CurrentScaleFactor = Math::Min(CurrentScaleFactor, 1.0);

		MeshOffsetComponent.SetWorldScale3D(OriginalScale * CurrentScaleFactor);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!MoveComp.IsOnAnyGround())
			AirTime += DeltaTime;
		else
			AirTime = 0.0;
	}

}