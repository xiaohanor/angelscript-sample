event void FOnHitByTailAttack(FTailAttackParams Params);
event void FOnHitByRoll(FRollParams Params);
event void FOnHitByRollAreaAttack(FRollAreaAttackParams Params);
event void FOnHitByGroundPoundAttack(FGroundPoundAttackParams Params);

enum ETailAttackImpactType
{
	Nature,
	Metal,
	Enemy
}

struct FTailAttackParams
{
	UPROPERTY()
	UPrimitiveComponent AttackComponent;
	UPROPERTY()
	FVector WorldAttackLocation;
	UPROPERTY()
	FVector AttackDirection;
	UPROPERTY()
	FVector AttackForwardVector;
	UPROPERTY()
	float DamageDealt = 0.0;
	UPROPERTY()
	AHazePlayerCharacter PlayerInstigator;
};

struct FRollParams
{
	UPROPERTY()
	UPrimitiveComponent HitComponent;
	UPROPERTY()
	FVector HitLocation;
	UPROPERTY()
	FVector RollDirection;
	UPROPERTY()
	FVector WallNormal;
	UPROPERTY()
	AHazePlayerCharacter PlayerInstigator;
	UPROPERTY()
	float DamageDealt = 0.0;
	UPROPERTY()
	float SpeedAtHit = 0.0;
	UPROPERTY()
	float SpeedTowardsImpact = 0.0;
};

struct FRollAreaAttackParams
{
	UPROPERTY()
	FVector AreaCenterLocation;
	UPROPERTY()
	float AreaRadius;
	UPROPERTY()
	float DamageDealt = 0.0;
	UPROPERTY()
	AHazePlayerCharacter PlayerInstigator;
};

struct FGroundPoundAttackParams
{
	UPROPERTY()
	FVector AreaCenterLocation;
	UPROPERTY()
	float AreaRadius;
	UPROPERTY()
	float DamageDealt = 0.0;
	UPROPERTY()
	AHazePlayerCharacter PlayerInstigator;
};
	
class UTeenDragonTailAttackResponseComponent : USceneComponent
{
	access TeenDragonRollingSystem = protected, UTeenDragonRollComponent, UTeenDragonRollMovementResolver;

	UPROPERTY(EditAnywhere)
	ETailAttackImpactType ImpactType = ETailAttackImpactType::Metal;

	UPROPERTY()
	FOnHitByTailAttack OnHitByTailAttack;

	UPROPERTY()
	FOnHitByRoll OnHitByRoll;

	/* If dragon should roll through the component or not
		WARNING: SHOULD ONLY BE TICKED IF THE THING YOU ROLL THROUGH DISAPPEARS NEXT FRAME (Gets destroyed)
	*/
	UPROPERTY(EditAnywhere)
	bool bShouldStopPlayer = true;

	// If true, this will only trigger events when the parent component is hit
	UPROPERTY(EditAnywhere)
	bool bIsPrimitiveParentExclusive = false;

	UPROPERTY(EditAnywhere)
	bool bEnabled = true;

	UPROPERTY(EditAnywhere)
	bool bGroundImpactValid = true;

	UPROPERTY(EditAnywhere)
	bool bWallImpactValid = true;

	UPROPERTY(EditAnywhere)
	bool bCeilingImpactValid = true;

	UPROPERTY(EditAnywhere)
	bool bOverrideNormalDirectionWithForward = false;

	UPROPERTY(EditAnywhere)
	UTeenDragonRollWallKnockbackSettings OverridingKnockbackSettings;

	UPROPERTY()
	FOnHitByRollAreaAttack OnHitByRollAreaAttack;

	UPROPERTY()
	FOnHitByGroundPoundAttack OnHitByGroundPoundAttack;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bIsPrimitiveParentExclusive)
		{
			auto CompAttachParent = GetAttachParent();
			auto PrimitiveParent = Cast<UPrimitiveComponent>(CompAttachParent);
			devCheck(PrimitiveParent != nullptr, f"{this} on {Owner} is set to 'bIsPrimitiveParentExclusive' but its parent component is not a primitive");
		}
	}

	access: TeenDragonRollingSystem
	void ActivateRollHit(FRollParams Params)
	{
		OnHitByRoll.Broadcast(Params);
	}

	bool ImpactWasOnParent(UPrimitiveComponent ComponentHit) const 
	{
		auto PrimitiveParent = Cast<UPrimitiveComponent>(GetAttachParent());
		if(PrimitiveParent != nullptr && PrimitiveParent == ComponentHit)
			return true;

		return false;
	}
};