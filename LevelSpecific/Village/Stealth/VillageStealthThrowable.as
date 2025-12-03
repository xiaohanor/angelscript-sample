event void FVillageStealthThrowableHitEvent(bool bHitOgre);

UCLASS(Abstract)
class AVillageStealthThrowable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ThrowableRoot;

	UPROPERTY()
	FVillageStealthThrowableHitEvent OnHit;

	bool bThrown = false;
	float ThrowDistance = 0.0;
	float ThrowAlpha = 0.0;
	float ThrowSpeed = 1600.0;
	float ThrowHeight = 200.0;

	FHazeRuntimeSpline ThrowSpline;

	float ThrowableRadius = 7.0;
	
	bool bImpacted = false;
	AHazePlayerCharacter ThrowedBy;

	void PickUp()
	{
		bThrown = false;
		ThrowAlpha = 0.0;
		ThrowDistance = 0.0;
		bImpacted = false;

		RemoveActorDisable(this);
		UVillageStealthThrowableEffectEventHandler::Trigger_Pickup(this);
		
	}

	UFUNCTION()
	void Throw(FHazeRuntimeSpline Spline)
	{
		if (bThrown)
			return;

		DetachFromActor(EDetachmentRule::KeepWorld);

		ThrowSpline = Spline;
		bThrown = true;

		UVillageStealthThrowableEffectEventHandler::Trigger_Throw(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bThrown)
			return;

		if (bImpacted)
			return;

		ThrowDistance = Math::Clamp(ThrowDistance + ThrowSpeed * DeltaTime,0.0, ThrowSpline.Length);
		ThrowAlpha = Math::Lerp(0.0, 1.0, ThrowDistance/ThrowSpline.Length);

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::EnemyCharacter);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(this);
		Trace.UseSphereShape(ThrowableRadius);

		FVector NewLocation = ThrowSpline.GetLocation(ThrowAlpha);
		if (!NewLocation.Equals(ActorLocation))
		{
			AVillageStealthOgre Ogre = nullptr;
			FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, NewLocation);
			if (Hit.bBlockingHit)
			{
				Ogre = Cast<AVillageStealthOgre>(Hit.Actor);
				if (ThrowedBy.HasControl())
					CrumbTriggerImpact(Ogre);
			}
		}

		SetActorLocation(NewLocation);
		AddActorLocalRotation(FRotator(45.0, 60.0, 75.0) * 5.0 * DeltaTime);

		if (ThrowAlpha >= 1.0 && !bImpacted && ThrowedBy.HasControl())
			CrumbTriggerImpact();
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerImpact(AVillageStealthOgre Ogre = nullptr)
	{
		BP_Impact();

		UVillageStealthThrowableEffectEventHandler::Trigger_Impact(this);

		bool bHitOgre = Ogre != nullptr;
		OnHit.Broadcast(bHitOgre);
		bThrown = false;
		bImpacted = true;

		if (bHitOgre)
			Ogre.HitByThrowable();

		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Impact() {}
}

class UVillageStealthThrowableEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Pickup() {}
	UFUNCTION(BlueprintEvent)
	void Throw() {}
	UFUNCTION(BlueprintEvent)
	void Impact() {}
}