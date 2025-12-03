event void FGravityWhipImpactSignature(FGravityWhipImpactData ImpactData);
event void FGravityWhipRadialImpactSignature(FGravityWhipRadialImpactData ImpactData);

struct FGravityWhipImpactData
{
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactVelocity;

	UPROPERTY(BlueprintReadOnly)
	FHitResult HitResult;

	UPROPERTY(BlueprintReadOnly)
	float Damage;

	UPROPERTY(BlueprintReadOnly)
	AActor ThrownActor;
}

struct FGravityWhipRadialImpactData
{
	UPROPERTY(BlueprintReadOnly)
	float Damage;
}

class UGravityWhipImpactResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FGravityWhipImpactSignature OnImpact;

	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FGravityWhipRadialImpactSignature OnRadialImpact;

	UPROPERTY(EditAnywhere)
	bool bIsNonStopping = false;

	UPROPERTY(EditAnywhere)
	float VelocityScaleAfterImpact = 0.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		if(HazeOwner != nullptr)
			HazeOwner.JoinTeam(n"GravityWhipImpactTeam");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		if(HazeOwner != nullptr)
			HazeOwner.LeaveTeam(n"GravityWhipImpactTeam");
	}

	void Impact(FGravityWhipImpactData ImpactData)
	{
		OnImpact.Broadcast(ImpactData);
	}

	void RadialImpact(FGravityWhipRadialImpactData ImpactData)
	{
		OnRadialImpact.Broadcast(ImpactData);
	}

	UFUNCTION(CrumbFunction)
	void CrumbImpact(FGravityWhipImpactData ImpactData)
	{
		Impact(ImpactData);
	}
}