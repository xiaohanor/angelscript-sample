UCLASS(Abstract)
class UPrisonGuardEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
	USceneComponent RightZapper;

	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
	USceneComponent LeftZapper;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RightZapper = USceneComponent::Get(Owner, n"RightZapper");	
		LeftZapper = USceneComponent::Get(Owner, n"LeftZapper");	
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRespawn() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath(FPrisonGuardDamageParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttackStart(FPrisonGuardAttackParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttackStop(FPrisonGuardAttackParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStunnedStart(FPrisonGuardDamageParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStunnedStop() {}

	UFUNCTION()
	void UpdateZap(UNiagaraComponent ZapEffect, USceneComponent Zapper, AHazeActor Target, float DeltaTime)
	{
		if (ZapEffect == nullptr)
			return;

		ZapEffect.SetFloatParameter(n"BeamWidth", 0.1);
		ZapEffect.SetVectorParameter(n"Start", Zapper.WorldLocation);

		if (Target == nullptr)
		{
			// Just arc in front of zapper
			FVector MissLoc = Owner.ActorLocation + Owner.ActorForwardVector * 50.0 + FVector(0.0, 0.0, 80.0);
			ZapEffect.SetVectorParameter(n"End", MissLoc);
		}
		else
		{
			FVector TargetLoc = Target.ActorCenterLocation;
			UHazeSkeletalMeshComponentBase Mesh = UHazeSkeletalMeshComponentBase::Get(Target);
			if ((Mesh != nullptr) && Mesh.DoesSocketExist(n"Hips"))
				TargetLoc = Mesh.GetSocketLocation(n"Hips");
			ZapEffect.SetVectorParameter(n"End", TargetLoc);
		}
	}
}

struct FPrisonGuardAttackParams
{
	UPROPERTY()
	AHazeActor Target;

	UPROPERTY()
	float MaxDuration;

	FPrisonGuardAttackParams(AHazeActor HitTarget, float Duration)
	{
		Target = HitTarget;
		MaxDuration = Duration;
	}
}

struct FPrisonGuardDamageParams
{
	UPROPERTY()
	FVector Direction;

	FPrisonGuardDamageParams(FVector Dir)
	{
		Direction = Dir;
	}
}
