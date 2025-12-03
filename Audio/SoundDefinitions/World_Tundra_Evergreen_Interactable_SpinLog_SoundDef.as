
UCLASS(Abstract)
class UWorld_Tundra_Evergreen_Interactable_SpinLog_SoundDef : USpot_Tracking_SoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	TSoftObjectPtr<AEvergreenSpinLog> SpinLogActor;

	UHazeCrumbSyncedRotatorComponent SyncedRotatorComp;

	UFUNCTION(BlueprintEvent)
	void OnStartMoving(bool bIsForward) {};

	UFUNCTION(BlueprintEvent)
	void OnStopMoving() {};

	UFUNCTION(BlueprintEvent)
	void TickMoving(float DeltaSeconds) {};

	UPROPERTY(Category = "Movement")
	float MaxRotationSpeed = 700;

	UFUNCTION(BlueprintPure)
	void GetRotationSpeedNormalized(float&out Speed, float&out Direction)
	{
		Speed = Math::Min(1.0, CachedRotationSpeed / MaxRotationSpeed);
		Direction = DirectionValue;
	}

	UFUNCTION(BlueprintPure)
	float GetAlphaValue()
	{
		return Alpha;
	}

	private float Alpha = 0.0;
	private float PreviousAlpha = 0.0;
	private float DirectionValue = 0.0;

	private bool bIsMoving = false;
	private bool bWasMoving = false;
	
	private float CachedRotationSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Super::ParentSetup();

		auto EvergreenLogActor = SpinLogActor.Get();
		SyncedRotatorComp = UHazeCrumbSyncedRotatorComponent::Get(EvergreenLogActor);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		Super::TickActive(DeltaSeconds);

		if (SyncedRotatorComp != nullptr)
			Alpha = SyncedRotatorComp.GetValue().Roll;

		bIsMoving = (Alpha != PreviousAlpha);
		if(!bIsMoving)
		{
			DirectionValue = 0.0;

			if(bWasMoving)
				OnStopMoving();
		}
		else
		{
			DirectionValue = Math::Sign(Alpha - PreviousAlpha);

			if(!bWasMoving)
			{
				bool bIsForward = DirectionValue > 0;
				OnStartMoving(bIsForward);	
			}

			TickMoving(DeltaSeconds);
		}

		const float Delta = Alpha - PreviousAlpha;
		CachedRotationSpeed = Math::Abs(Delta) / DeltaSeconds;

		PreviousAlpha = Alpha;
		bWasMoving = bIsMoving;
	}
}