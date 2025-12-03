struct FGravityBikeBladeOnMountedEventData
{
	UPROPERTY()
	AGravityBikeSpline GravityBike;
}

struct FGravityBikeBladeThrowEventData
{
	UPROPERTY()
	AGravityBikeBlade BladeActor;

	UPROPERTY()
	FVector TargetLocation;

	UPROPERTY()
	FVector TargetNormal;

	UPROPERTY(BlueprintReadOnly)
	float ThrowDuration = 0.0;
}

/**
 * Placed on the Player wielding the Gravity Blade (Mio)
 */
UCLASS(Abstract)
class UGravityBikeBladeEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	UGravityBikeBladePlayerComponent BladeComp;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	private AGravityBikeSpline GravityBike;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeComp = UGravityBikeBladePlayerComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);

		BladeComp.DriverComp.OnPlayerMounted.AddUFunction(this, n"OnMounted");
	}

	UFUNCTION()
	private void OnMounted(AGravityBikeSpline InGravityBike)
	{
		GravityBike = InGravityBike;

		FGravityBikeBladeOnMountedEventData EventData;
		EventData.GravityBike = GravityBike;
		OnPlayerMountedGravityBike(EventData);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerMountedGravityBike(FGravityBikeBladeOnMountedEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGravityTriggerEntered() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGravityTriggerExited() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrowStarted(FGravityBikeBladeThrowEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrowStopped(FGravityBikeBladeThrowEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGravityChangeStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGravityChangeStopped() {}

	UFUNCTION(BlueprintPure)
	AGravityBikeSpline GetGravityBike() const
	{
		devCheck(GravityBike != nullptr, "Trying to get the gravity bike too early on the blade event handler. Get the bike from OnPlayerMountedGravityBike, or check IsMounted before trying to get the bike.");
		return GravityBike;
	}

	UFUNCTION(BlueprintCallable, Meta = (AdvancedDisplay = "StartLocationName, StartTangentName, EndTangentName, EndLocationName"))
	void SetNiagaraBeamParameters(UNiagaraComponent NiagaraComponent,
		FVector StartLocation,
		FVector StartTangent,
		FVector EndTangent,
		FVector EndLocation,
		const FString& StartLocationName = "P0",
		const FString& StartTangentName = "P1",
		const FString& EndTangentName = "P2",
		const FString& EndLocationName = "P3") const
	{
		if (NiagaraComponent == nullptr ||
			NiagaraComponent.IsBeingDestroyed())
			return;

		NiagaraComponent.SetNiagaraVariableVec3(StartLocationName, StartLocation);
		NiagaraComponent.SetNiagaraVariableVec3(StartTangentName, StartTangent);
		NiagaraComponent.SetNiagaraVariableVec3(EndTangentName, EndTangent);
		NiagaraComponent.SetNiagaraVariableVec3(EndLocationName, EndLocation);
	}
};