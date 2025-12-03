enum EHydraPlatformAttack
{
	Laser,
	Bite,
	Blow
}

struct FHydraPlatformData
{
	UPROPERTY()
	EHydraPlatformAttack AttackType = EHydraPlatformAttack::Laser;

	UPROPERTY()
	FTransform StartTransform;

	UPROPERTY()
	FTransform EndTransform;

	UPROPERTY()
	float AnticipationDuration = 2.0;

	UPROPERTY()
	float AttackDuration = 5.0;

	UPROPERTY()
	ASanctuaryBossLoopingPlatform TargetPlatform = nullptr;
}

class ASanctuaryBossPlatformHydra : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadPivotComp;

	UPROPERTY(DefaultComponent, Attach = HeadPivotComp)
	UDecalComponent LaserTelegraphDecal;

	UPROPERTY(DefaultComponent, Attach = HeadPivotComp)
	UStaticMeshComponent LaserMeshComp;

	UPROPERTY(DefaultComponent, Attach = HeadPivotComp)
	UStaticMeshComponent HeadMeshComp;

	UPROPERTY(DefaultComponent, Attach = HeadPivotComp)
	UStaticMeshComponent UpperJawMeshComp;

	UPROPERTY(DefaultComponent, Attach = HeadPivotComp)
	UStaticMeshComponent LowerJawMeshComp;

	UPROPERTY(DefaultComponent, Attach = HeadPivotComp)
	UHazeCapsuleCollisionComponent LaserCollisionComp;

	UPROPERTY(DefaultComponent, Attach = HeadPivotComp)
	UNiagaraComponent BlowVFX;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike AttackAnticipationTimeLike;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike BiteTimeLike;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike LaserTimeLike;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike BlowTimeLike;

	UPROPERTY(Category = Materials)
	UMaterialInstance TelegraphMaterial;

	UPROPERTY(Category = Materials)
	UMaterialInstance LaserMaterial;

	UPROPERTY(BlueprintReadOnly)
	ASanctuaryBossPhase2Manager Manager;

	UPROPERTY(BlueprintReadOnly)
	ASplineFollowFocusTrackerCameraActor Camera;

	UPROPERTY(Category = HydraPlatformDataSetup, EditAnywhere)
	bool bSetStartTransform;

	UPROPERTY(Category = HydraPlatformDataSetup, EditAnywhere)
	bool bSetEndTransform;

	UPROPERTY(Category = Settings, EditAnywhere)
	FHazeCameraWeightedFocusTargetInfo CameraInfo;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossPlatformHydraFocusTargetActor FocusTargetActor;

	FHydraPlatformData PlatformData;

	float PreviousBlowSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AttackAnticipationTimeLike.BindUpdate(this, n"AttackAnticipationTimeLikeUpdate");
		AttackAnticipationTimeLike.BindFinished(this, n"AttackAnticipationTimeLikeFinished");
		BiteTimeLike.BindUpdate(this, n"BiteTimeLikeUpdate");
		BiteTimeLike.BindFinished(this, n"BiteTimeLikeFinished");
		LaserTimeLike.BindUpdate(this, n"LaserTimeLikeUpdate");
		LaserTimeLike.BindFinished(this, n"LaserTimeLikeFinished");
		BlowTimeLike.BindUpdate(this, n"BlowTimeLikeUpdate");
		BlowTimeLike.BindFinished(this, n"BlowTimeLikeFinished");
		LaserCollisionComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleLaserBeginOverlap");
		LaserCollisionComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

/* 	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bSetStartTransform)
		{
			Manager.HydraPlatformManagerDataBuilder.InData.StartTransform = HeadPivotComp.WorldTransform.GetRelativeTransform(Manager.ActorTransform);

			Manager.HydraPlatformManagerDataBuilder.HeadActor = this;

			bSetStartTransform = false;

			PrintToScreen("Start transform data sent", 3.0);
		}

		if (bSetEndTransform)
		{
			Manager.HydraPlatformManagerDataBuilder.InData.EndTransform = HeadPivotComp.WorldTransform.GetRelativeTransform(Manager.ActorTransform);

			Manager.HydraPlatformManagerDataBuilder.HeadActor = this;

			bSetEndTransform = false;
		}
	} */

	UFUNCTION()
	private void HandleLaserBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter OverlappingPlayer = Cast<AHazePlayerCharacter>(OtherActor);

		if (IsValid(OverlappingPlayer))
			OverlappingPlayer.KillPlayer();
	}

	UFUNCTION()
	void StartAttack(FHydraPlatformData InData)
	{
		PlatformData = InData;

		PrintToScreen("Started Attack", 3.0);

		HeadPivotComp.SetWorldLocationAndRotation(PlatformData.StartTransform.Location, PlatformData.StartTransform.Rotation);

		Timer::SetTimer(this, n"Attack", PlatformData.AnticipationDuration);

		//Camera.FocusTargetComponent.AddWeightedFocusTarget(CameraInfo, this);
	}

	UFUNCTION()
	private void EndAttack()
	{
		//Camera.FocusTargetComponent.BP_RemoveAllAddFocusTargetsByInstigator(this);
		HeadPivotComp.SetWorldLocationAndRotation(ActorLocation, ActorRotation);
	}

	UFUNCTION()
	private void Attack()
	{
		switch (PlatformData.AttackType)
		{

			// Laser

			case EHydraPlatformAttack::Laser:

				OnTelegraphStarted();

			break;

			default:
			break;
		}

		AttackAnticipationTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void Blow()
	{

	}

	UFUNCTION(BlueprintEvent)
	void OnTelegraphStarted()
	{

	}

	UFUNCTION(BlueprintEvent)
	void OnAttackStarted()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void OnAttackFinished()
	{
		
	}

	//TimeLike Functions 

	UFUNCTION()
	private void AttackAnticipationTimeLikeUpdate(float Alpha)
	{
		UpperJawMeshComp.SetRelativeRotation(FRotator(Math::Lerp(-90.0, -60.0, Alpha), 0.0, 0.0));
		LowerJawMeshComp.SetRelativeRotation(FRotator(Math::Lerp(-90.0, -120.0, Alpha), 0.0, 0.0));
		PrintToScreen("AttackAnticipationUpdating");
	}

	UFUNCTION()
	private void AttackAnticipationTimeLikeFinished()
	{
		if (Math::IsNearlyEqual(AttackAnticipationTimeLike.Value, 1.0))
		{
		
			switch (PlatformData.AttackType)
			{

				// Laser

				case EHydraPlatformAttack::Laser:

					OnAttackStarted();
					LaserTimeLike.Duration = PlatformData.AttackDuration;
					LaserTimeLike.PlayFromStart();
					LaserCollisionComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

				break;

				// Bite

				case EHydraPlatformAttack::Bite:

					BiteTimeLike.Duration = PlatformData.AttackDuration;
					BiteTimeLike.PlayFromStart();

				break;

				case EHydraPlatformAttack::Blow:

					BlowVFX.Activate();
					PreviousBlowSpeed = Manager.PlatformSpeed;
					BlowTimeLike.PlayFromStart();

				break;
			}
		}
	}


	UFUNCTION()
	private void BiteTimeLikeUpdate(float Alpha)
	{
		UpperJawMeshComp.SetRelativeRotation(FRotator(Math::Lerp(-60.0, -90.0, Alpha), 0.0, 0.0));
		LowerJawMeshComp.SetRelativeRotation(FRotator(Math::Lerp(-120.0, -90.0, Alpha), 0.0, 0.0));

		HeadPivotComp.SetWorldLocation(Math::Lerp(PlatformData.StartTransform.Location, PlatformData.TargetPlatform.ActorLocation, Alpha * 0.5));			
	}

	UFUNCTION()
	private void BiteTimeLikeFinished()
	{
		EndAttack();
		PlatformData.TargetPlatform.OnPlatformSmashed();
	}


	UFUNCTION()
	private void LaserTimeLikeUpdate(float Alpha)
	{
		HeadPivotComp.SetWorldLocationAndRotation(Math::Lerp(PlatformData.StartTransform.Location, PlatformData.EndTransform.Location, Alpha), 
												Math::LerpShortestPath(PlatformData.StartTransform.Rotation.Rotator(), PlatformData.EndTransform.Rotation.Rotator(), Alpha));			
	}

	UFUNCTION()
	private void LaserTimeLikeFinished()
	{
		AttackAnticipationTimeLike.Reverse();
		EndAttack();
		OnAttackFinished();
		LaserCollisionComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	private void BlowTimeLikeUpdate(float Alpha)
	{
		Manager.PlatformSpeed = Math::Lerp(PreviousBlowSpeed, PlatformData.AttackDuration, Alpha);
	}

	UFUNCTION()
	private void BlowTimeLikeFinished()
	{
		BlowVFX.Deactivate();
		EndAttack();
		AttackAnticipationTimeLike.Reverse();
	}
};