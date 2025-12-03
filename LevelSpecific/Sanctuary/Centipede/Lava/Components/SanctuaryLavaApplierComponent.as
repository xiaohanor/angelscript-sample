class USanctuaryLavaApplierComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Lava Damage")
	float DamagePerSecond = 0.2;
	
	UPROPERTY(EditAnywhere, Category = "Lava Damage")
	float DamageDuration = 0.3;
	
	UPROPERTY(EditAnywhere, Category = "Lava Damage")
	float OverlappingApplyLavaRate = 0.2;

	UPROPERTY(EditAnywhere, Category = "Lava Damage")
	float BurnBodyRadius = 200.0;

	UPROPERTY(EditAnywhere, Category = "Lava Damage")
	bool bTriggerForceFeedback = true;

	UPROPERTY(EditAnywhere, Category = "Lava Damage")
	bool bDeathEvenIfInfiniteHealth = false;

	UPROPERTY()
	bool bOverlapTrigger = true;
	UPROPERTY()
	bool bOverlapMesh = false;

	float ApplyTickTimer = 0.0;
	private bool bIsManualOverlapping = false;

	float AliveDuration = 0.0;
	bool bSpecialCaseDisabled = false;

	UCentipedeLavaResponseComponent LavaResponseComponent;
	TArray<UCentipedeSegmentComponent> OverlappedCentipedeParts;
	ACentipede Centipede;
	TSubclassOf<AHazeActor> OwnerClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwnerClass = Owner.GetClass();
		if (bOverlapTrigger)
		{
			TArray<UShapeComponent> ShapeComps;
			Owner.GetComponentsByClass(UShapeComponent, ShapeComps);
			for (auto TriggerComp : ShapeComps)
			{
				if (TriggerComp.Owner.IsA(AHazePlayerCharacter))
					continue;
				TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleTriggerOverlap");
				TriggerComp.OnComponentEndOverlap.AddUFunction(this, n"EndOverlap");
				TriggerComp.bDisableUpdateOverlapsOnComponentMove = true;
				if (BurnBodyRadius > TriggerComp.GetBoundsRadius())
					BurnBodyRadius = TriggerComp.GetBoundsRadius();
			}
		}
		
		if (bOverlapMesh)
		{
			TArray<UStaticMeshComponent> MeshComps;
			Owner.GetComponentsByClass(UStaticMeshComponent, MeshComps);
			for (auto MeshComp : MeshComps)
			{
				if (MeshComp.Owner.IsA(AHazePlayerCharacter))
					continue;
				MeshComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleTriggerOverlap");
				MeshComp.OnComponentEndOverlap.AddUFunction(this, n"EndOverlap");
				MeshComp.bDisableUpdateOverlapsOnComponentMove = true;
				if (BurnBodyRadius > MeshComp.GetBoundsRadius())
					BurnBodyRadius = MeshComp.GetBoundsRadius();
			}
		}

		AliveDuration = 0.0;
	}

	UFUNCTION()
	private void HandleTriggerOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (IsValid(OtherActor))
		{
			ACentipede Cento = Cast<ACentipede>(OtherActor);
			UCentipedeSegmentComponent CentoSegment = Cast<UCentipedeSegmentComponent>(OtherComp);
			if (IsValid(Cento) && CentoSegment != nullptr)
			{
				OverlappedCentipedeParts.AddUnique(CentoSegment);
			}
		}
	}

	UFUNCTION()
	private void EndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if (IsValid(OtherActor))
		{
			ACentipede Cento = Cast<ACentipede>(OtherActor);
			UCentipedeSegmentComponent CentoSegment = Cast<UCentipedeSegmentComponent>(OtherComp);
			if (IsValid(Cento) && CentoSegment != nullptr && OverlappedCentipedeParts.Contains(CentoSegment))
			{
				OverlappedCentipedeParts.Remove(CentoSegment);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbMortarOverlap(FVector MortarLocation, float Radius)
	{
	}

	UFUNCTION()
	bool OverlapSingleFrame(FVector Location, float Radius, bool bReset)
	{
		ApplyTickTimer = 0.0;
		LazyAssignCentipede();

		if (Centipede == nullptr) // happens in aviation tutorial
			return false;

		if (bReset)
		{
			OverlappedCentipedeParts.Reset(32);
		}

		for (int i = 0; i < Centipede.Segments.Num(); ++i) 
		{
			if (Location.Distance(Centipede.Segments[i].WorldLocation) < Radius)
				TryAddOverlap(Centipede.Segments[i]);
		}

		ApplyLavaHit();
		bool bOverlapSuccess = OverlappedCentipedeParts.Num() > 0;
		ManualEndOverlapWholeCentipedeApply();

		return bOverlapSuccess;
	}

	private void TryAddOverlap(UCentipedeSegmentComponent Segment)
	{
		if (Segment.IsLavaInvulnerable())
			return;
		OverlappedCentipedeParts.AddUnique(Segment);
	}

	UFUNCTION()
	bool ManualSetIsOverlapping(UHazeCapsuleCollisionComponent Overlapper, bool bReset)
	{
		LazyAssignCentipede();
		if (Centipede == nullptr)
			return false;

		float Distancing = Centipede.ActorLocation.Distance(Overlapper.Owner.ActorLocation);
		bool bCulled = Distancing > 10000.0;
		if (bCulled)
			return false;

		if (Overlapper.CollisionEnabled == ECollisionEnabled::NoCollision)
			return false;

		auto Trace = Trace::InitFromPrimitiveComponent(Overlapper);
		auto Overlaps = Trace.QueryOverlaps(Overlapper.WorldLocation);

		if (bReset)
		{
			OverlappedCentipedeParts.Reset(32);
		}

		for (auto Overlap : Overlaps)
		{
			UCentipedeSegmentComponent CentoSegment = Cast<UCentipedeSegmentComponent>(Overlap.Component);
			if (IsValid(CentoSegment))
				TryAddOverlap(CentoSegment);
		}
		
		bool bWasOverlapping = bIsManualOverlapping;
		bIsManualOverlapping = OverlappedCentipedeParts.Num() > 0;
		if (!bWasOverlapping && bIsManualOverlapping)
			ApplyTickTimer = 0.0;

		return OverlappedCentipedeParts.Num() > 0;
	}

	private void LazyAssignCentipede()
	{
		if (Centipede == nullptr)
		{
			UPlayerCentipedeComponent PlayerCentipedeComp = UPlayerCentipedeComponent::Get(Game::Mio);
			Centipede = PlayerCentipedeComp.Centipede;
		}
	}

	UFUNCTION()
	void ManualStartOverlapWholeCentipedeApply()
	{
		bIsManualOverlapping = true;
		ApplyTickTimer = 0.0;
		StartOverlapAllCentipedeSegments();
	}

	UFUNCTION()
	void ManualEndOverlapWholeCentipedeApply()
	{
		bIsManualOverlapping = false;
		StopOverlapAllCentipedeSegments();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AliveDuration += DeltaSeconds;
		if (AliveDuration < 0.1)
			return; // hack because Hannes doesn't want to move the lava death volume sitting on the checkpoint after the lava moles

		if (bSpecialCaseDisabled)
			return;

		if (OverlappedCentipedeParts.Num() == 0)
			return;

		if (IsRespawning())
		{
			OverlappedCentipedeParts.Reset(32);
			return;
		}

		ApplyTickTimer -= DeltaSeconds;
		if (ApplyTickTimer <= 0)
		{
			ApplyLavaHit();
			ApplyTickTimer = OverlappingApplyLavaRate;
		}
	}

	UFUNCTION()
	void SingleApplyLavaHitOnWholeCentipede()
	{
		LazyAssignCentipede();
		if (Centipede == nullptr)
			return; // can happen in flying tutorial intro!
		OverlappedCentipedeParts.Reset(32);
		for (int i = 0; i < Centipede.Segments.Num(); ++i) 
			TryAddOverlap(Centipede.Segments[i]);
		ApplyLavaHit();
		OverlappedCentipedeParts.Reset(32);
	}

	private void StartOverlapAllCentipedeSegments()
	{
		LazyAssignCentipede();

		for (int i = 0; i < Centipede.Segments.Num(); ++i) 
			TryAddOverlap(Centipede.Segments[i]);
	}

	private void StopOverlapAllCentipedeSegments()
	{
		LazyAssignCentipede();
		OverlappedCentipedeParts.Reset(32);
	}

	private bool IsRespawning()
	{
		if (LavaResponseComponent == nullptr || Centipede == nullptr)
		{
			UPlayerCentipedeComponent PlayerCentipedeComp = UPlayerCentipedeComponent::Get(Game::Mio);
			if (PlayerCentipedeComp == nullptr)
				return false;
			Centipede = PlayerCentipedeComp.Centipede;
			LavaResponseComponent = UCentipedeLavaResponseComponent::Get(PlayerCentipedeComp.Centipede);
		}

		if (LavaResponseComponent == nullptr)
			return false;

		return LavaResponseComponent.LavaIntoleranceComponent.bIsRespawning;
	}

	private void ApplyLavaHit()
	{
		if (IsRespawning())
			return;

		if (OverlappedCentipedeParts.Num() == 0)
			return;

		FCentipedeLavaHitParams LavaHitParams;
		LavaHitParams.DamagePerSecond = DamagePerSecond;
		LavaHitParams.DamageDuration = DamageDuration;
		LavaHitParams.bTriggerForceFeedback = bTriggerForceFeedback;
		LavaHitParams.SourceDamager = OwnerClass;
		LavaHitParams.bDeathEvenIfInfiniteHealth = bDeathEvenIfInfiniteHealth;
		for (auto Part : OverlappedCentipedeParts)
			LavaHitParams.SegmentIndexes.Add(Part.SegmentIndex);
		LavaResponseComponent.OnLavaHitEvent.Broadcast(LavaHitParams);
	}
};