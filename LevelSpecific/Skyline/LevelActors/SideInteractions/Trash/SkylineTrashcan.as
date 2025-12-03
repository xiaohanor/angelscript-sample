class ASkylineTrashcan : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent NotDestroyedRoot;

	UPROPERTY(DefaultComponent, Attach = NotDestroyedRoot)
	USceneComponent Base;

	UPROPERTY(DefaultComponent, Attach = Base)
	UStaticMeshComponent TrashcanBase;

	UPROPERTY(DefaultComponent, Attach = NotDestroyedRoot)
	UFauxPhysicsAxisRotateComponent FauxRotateLidComp;

	UPROPERTY(DefaultComponent, Attach = FauxRotateLidComp)
	UStaticMeshComponent TrashcanLid;

	UPROPERTY(DefaultComponent, Attach = NotDestroyedRoot)
	UGravityWhipSlingAutoAimComponent WhipAutoAimComp;
	default WhipAutoAimBackComp.bInvisibleTarget = true;

	UPROPERTY(DefaultComponent, Attach = NotDestroyedRoot)
	UGravityWhipSlingAutoAimComponent WhipAutoAimBackComp;
	default WhipAutoAimBackComp.bInvisibleTarget = true;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent AttackedResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem DebrisVFX;

	bool bAlignedForNow = true;

	bool bIsAligned = true;

	float AutoAlignCooldown = 1.0;

	UPROPERTY(EditAnywhere)
	ASplineActor ConstrainRollingCansSpline;
	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineRollingTrash> RollingTrashClass;
	int NumCansInside = 0;
	bool bSwallowedTrash = false;

	TArray<ASkylineThrowableTrash> IncomingTrashes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AttackedResponseComp.OnHit.AddUFunction(this, n"BladeHit");
	}

	UFUNCTION()
	private void BladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if (DebrisVFX != nullptr)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(DebrisVFX, ActorLocation, ActorRotation);
			USkylineTrashCanEventHandler::Trigger_HitByKatana(this);
			if (HasControl())
			{
				TArray<FVector> RandomImpulses;
				for (int iCan = 0; iCan < NumCansInside; ++iCan)
					RandomImpulses.Add(GetRandomImpulse());
				if (!RandomImpulses.IsEmpty())
					CrumbSpawnCans(RandomImpulses);
			}
		}
		SetActorHiddenInGame(true);
		SetActorEnableCollision(false);
		AttackedResponseComp.AddResponseComponentDisable(this, true);
		WhipAutoAimComp.Disable(this);
		WhipAutoAimBackComp.Disable(this);
	}

	private FVector GetRandomImpulse() const
	{
		FVector RandomImpulse = Math::GetRandomConeDirection(ActorForwardVector, Math::DegreesToRadians(80.0));
		RandomImpulse.Z = 0.3;
		return RandomImpulse.GetSafeNormal() * Math::RandRange(100.0, 1000.0);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSpawnCans(TArray<FVector> RandomImpulses)
	{
		if (RollingTrashClass == nullptr)
			return;

		if (ConstrainRollingCansSpline == nullptr)
			return;

		FVector SpawnLocation = ActorLocation + FVector::UpVector * 5.0; // can radius for faux physics
		for (int iCan = 0; iCan < RandomImpulses.Num(); ++iCan)
		{
			FVector RandomImpulse = RandomImpulses[iCan];
			ASkylineRollingTrash SpawnedActor = SpawnActor(RollingTrashClass, SpawnLocation, FRotator(), NAME_None, true);
			SpawnedActor.MakeNetworked(this, iCan);
			SpawnedActor.SetActorControlSide(Game::Zoe);
			SpawnedActor.FauxTranslationComp.OtherSplineActor = ConstrainRollingCansSpline;
			SpawnedActor.FauxTranslationComp.bClockwise = false;
			FQuat NewWorldRot = FQuat::ApplyRelative(FQuat::MakeFromZX(FVector::UpVector, RandomImpulse.GetSafeNormal()), SpawnedActor.FauxRotateComp.RelativeRotation.Quaternion());
			SpawnedActor.FauxRotateComp.SetWorldRotation(NewWorldRot);
			FinishSpawningActor(SpawnedActor);

			FVector Delta = ActorCenterLocation - SpawnedActor.FauxTranslationComp.WorldLocation;
			SpawnedActor.FauxTranslationComp.ApplyMovement(SpawnedActor.FauxTranslationComp.WorldLocation, Delta);
			SpawnedActor.FauxTranslationComp.ApplyImpulse(SpawnLocation, RandomImpulse);
			SpawnedActor.FauxRotateComp.ApplyAngularForce(Math::DegreesToRadians(360));
		}
		AddActorDisable(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbAddCan(float ThrowForce)
	{
		FauxRotateLidComp.ApplyAngularImpulse(Math::DegreesToRadians(ThrowForce));
		bAlignedForNow = false;
		bIsAligned = false;
		AutoAlignCooldown = 0.5;
		bSwallowedTrash = true;
		NumCansInside += 1;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto IncomingTrashy : IncomingTrashes)
		{
			if (IncomingTrashy == nullptr)
				continue;
			bool ForwardDist = IncomingTrashy.ActorLocation.Distance(WhipAutoAimComp.WorldLocation) < 50;
			bool BackDist = IncomingTrashy.ActorLocation.Distance(WhipAutoAimBackComp.WorldLocation) < 50;
			if (ForwardDist || BackDist || IncomingTrashy.MovementComponent.GroundContact.Actor == this || IncomingTrashy.MovementComponent.WallContact.Actor == this)
			{
				float ThrowForce = Math::RandRange(360.0 * 2.0, 360.0 * 7.0);
				if (IncomingTrashy.ActorLocation.DotProduct(ActorForwardVector) > 0.0)
					ThrowForce *= -1.0;

				if (Game::Zoe.HasControl())
					CrumbAddCan(ThrowForce);
				break;
			}
		}

		if (bSwallowedTrash)
		{
			bSwallowedTrash = false;
			IncomingTrashes.Empty();
			USkylineTrashCanEventHandler::Trigger_SlingableEnterTrashCan(this);
		}

		AutoAlignCooldown -= DeltaSeconds;
		bool bKindaAligned = AutoAlignCooldown < 0.0 && FauxRotateLidComp.UpVector.DotProduct(ActorUpVector) > 0.96 && Math::Abs(FauxRotateLidComp.Velocity) < 0.5;
		bAlignedForNow = bKindaAligned || bAlignedForNow;
		if (!bAlignedForNow)
		{
			bool bGravityDirectionClockwise = (FauxRotateLidComp.UpVector.DotProduct(ActorForwardVector) > 0.0);
			const float GravityForce = 980.0;

			if (bGravityDirectionClockwise)
				FauxRotateLidComp.ApplyAngularForce(Math::DegreesToRadians(-GravityForce));
			else
				FauxRotateLidComp.ApplyAngularForce(Math::DegreesToRadians(GravityForce));
		}
		else
		{
			FauxRotateLidComp.CurrentRotation = Math::Wrap(FauxRotateLidComp.CurrentRotation, -PI, PI);
			FauxRotateLidComp.CurrentRotation *= 0.5;

			if(!bIsAligned)
			{
				bIsAligned = true;

				USkylineTrashCanEventHandler::Trigger_TrashCanStopSpinning(this);
			}
		}

		// Debug::DrawDebugString(FauxRotateLidComp.WorldLocation, "" + FauxRotateLidComp.CurrentRotation);
	}
};