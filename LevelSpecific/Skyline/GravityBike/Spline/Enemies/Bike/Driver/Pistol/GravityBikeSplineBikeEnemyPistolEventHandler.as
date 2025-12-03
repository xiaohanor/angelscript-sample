struct FGravityBikeSplineBikeEnemyDriverPistolFireEventData
{
	UPROPERTY()
	UGravityBikeSplineBikeEnemyDriverPistolComponent PistolComponent;

	UPROPERTY()
	FVector StartLocation;

	UPROPERTY()
	FVector StartDirection;

	UPROPERTY()
	FHitResult HitResult;
};

UCLASS(Abstract)
class UGravityBikeSplineBikeEnemyDriverPistolEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AGravityBikeSplineBikeEnemyDriver Driver;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	UGravityBikeSplineBikeEnemyDriverPistolComponent PistolComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Driver = Cast<AGravityBikeSplineBikeEnemyDriver>(Owner);
		PistolComp = UGravityBikeSplineBikeEnemyDriverPistolComponent::Get(Driver);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPistolFire(FGravityBikeSplineBikeEnemyDriverPistolFireEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPistolFireTraceImpact(FGravityBikeSplineBikeEnemyDriverPistolFireEventData EventData) {}
};