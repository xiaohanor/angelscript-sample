event void FGravityWhipThrowHitSignature(FGravityWhipThrowHitData Data);

class UGravityWhipThrowResponseComponent : UActorComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Cast<AHazeActor>(Owner).JoinTeam(GravityWhipTags::GravityWhipThrowTargetTeam);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Cast<AHazeActor>(Owner).LeaveTeam(GravityWhipTags::GravityWhipThrowTargetTeam);
	}

	FGravityWhipThrowHitSignature OnHit;

	UPROPERTY()
	bool bNonThrowBlocking;
}

struct FGravityWhipThrowHitData
{
	UPROPERTY()
	float Damage;

	UPROPERTY()
	EDamageType DamageType = EDamageType::Default;

	UPROPERTY()
	AHazeActor Instigator;

	FGravityWhipThrowHitData(float InDamage, EDamageType InDamageType, AHazeActor InInstigator)
	{
		Damage = InDamage;
		DamageType = InDamageType;
		Instigator = InInstigator;
	}
}