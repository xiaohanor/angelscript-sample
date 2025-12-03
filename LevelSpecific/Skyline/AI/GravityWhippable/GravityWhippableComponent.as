event void FGravityWhippableOnThrownSignature();
event void FGravityWhippableOnImpactSignature();

class UGravityWhippableComponent : UActorComponent
{
	UPROPERTY()
	UGravityWhippableSettings DefaultWhippableSettings;

	UPROPERTY()
	FGravityWhippableOnThrownSignature OnThrown;


	UPROPERTY()
	FGravityWhippableOnImpactSignature OnImpact;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ImpactCameraShake;

	bool bThrown;
	bool bGrabbed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(DefaultWhippableSettings != nullptr)
		{
			AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
			HazeOwner.ApplySettings(DefaultWhippableSettings, this);
		}
	}
}