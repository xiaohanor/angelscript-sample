

/** This notify removes any previous tracked impacts, making it possible to hit the targets again */
class UPlayerIslandNunchuckTriggerAtLocationEffectNotify : UAnimNotify
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<APlayerIslandNunchuckTriggerAtLocationEffect> Effect;

	UPROPERTY(EditAnywhere)
	FName BoneName = n"Root";

	UPROPERTY(EditAnywhere)
	FRotator LocalRotationOffset = FRotator::ZeroRotator;

	UPROPERTY(EditAnywhere)
	FVector LocalTranslationOffset = FVector::ZeroVector;

	UPROPERTY(EditAnywhere)
	float LifeTime = 0.25;

	// Lerp the effect from left to right, instead of from right to left
	UPROPERTY(EditAnywhere)
	bool bInvertEffectTrail = false;

	// If we have a target, we use the direction to the target to spawn the effect in.
	UPROPERTY(EditAnywhere)
	bool bPreferToTargetOrientation = true;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve TrailCurve;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve VisibilityCurve;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "IslandNunchuck_TriggerEffect";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{	
		if(Effect == nullptr)
			return false;

		auto MeleeComp = UPlayerIslandNunchuckUserComponent::Get(MeshComp.GetOwner());
		if (MeleeComp == nullptr)
			return false;
	
		// FRotator ForwardRotator = MeshComp.GetOwner().GetActorRotation();
		// if(bPreferToTargetOrientation && !MeleeComp.LastTargetDirection.IsNearlyZero())
		// {
		// 	ForwardRotator = MeleeComp.LastTargetDirection.ToOrientationRotator();
		// }

		// FVector WorldLocation = (BoneName != NAME_None ? MeshComp.GetSocketLocation(BoneName) : MeshComp.GetOwner().ActorLocation) + ForwardRotator.RotateVector(LocalTranslationOffset);
		// FRotator WorldRotation = ForwardRotator + LocalRotationOffset;
		// auto SpawnedEffect = SpawnActor(Effect, WorldLocation, WorldRotation);
		// SpawnedEffect.LifeTime = LifeTime;
		// SpawnedEffect.bInvertEffect = bInvertEffectTrail;
		// SpawnedEffect.TrailCurve = TrailCurve;
		// SpawnedEffect.VisibilityCurve = VisibilityCurve;
		return true;
	}
}

