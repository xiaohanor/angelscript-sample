UCLASS(Abstract)
class UPrisonGuardBotEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnMagneticBurstStunnedStart() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnMagneticBurstStunnedEnd() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraphCharge() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnChargeStart() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnChargeEnd() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnExplode() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnZapStart(FPrisonGuardBotZapParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnZapStop(FPrisonGuardBotZapParams Params) {}

	UFUNCTION(BlueprintEvent)
	void OnShoot(FPrisonGuardBotShootParams Params) {}

	UFUNCTION(BlueprintEvent)
	void OnShootAtBadTarget() {}

	UFUNCTION(BlueprintEvent)
	void OnHitReactionStart() {}

	UFUNCTION(BlueprintEvent)
	void OnHitReactionStop() {}

	UFUNCTION()
	void UpdateZap(UNiagaraComponent ZapEffect, AHazeActor Target, float DeltaTime)
	{
		if (ZapEffect == nullptr)
			return;

		UPrisonGuardBotZapperMuzzleComponent ZapperComp = UPrisonGuardBotZapperMuzzleComponent::Get(Owner);	
		FVector ZapperMuzzleLoc = (ZapperComp == nullptr) ? Owner.ActorCenterLocation : ZapperComp.WorldLocation;
		ZapEffect.SetVectorParameter(n"BeamStart", ZapperMuzzleLoc);

		if (Target == nullptr)
		{
			// Just arc in front of zapper
			FVector MissLoc = ZapperMuzzleLoc + (Owner.ActorForwardVector + Game::Mio.ViewRotation.Vector()).GetClampedToSize(1, 1) * 500.0;
			ZapEffect.SetVectorParameter(n"BeamEnd", MissLoc);
		}
		else
		{
			FVector TargetLoc = Target.ActorCenterLocation;
			UHazeSkeletalMeshComponentBase Mesh = UHazeSkeletalMeshComponentBase::Get(Target);
			if ((Mesh != nullptr) && Mesh.DoesSocketExist(n"Hips"))
				TargetLoc = Mesh.GetSocketLocation(n"Hips");
			ZapEffect.SetVectorParameter(n"BeamEnd", TargetLoc);
		}
	}
}

struct FPrisonGuardBotZapParams
{
	UPROPERTY()
	AHazeActor Target;

	FPrisonGuardBotZapParams(AHazeActor HitTarget)
	{
		Target = HitTarget;
	}
}


struct FPrisonGuardBotShootParams
{
	UPROPERTY()
	FVector TargetLoc;
}