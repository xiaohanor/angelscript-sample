UCLASS(Abstract)
class ACentipede : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	// Centimesh
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultSheets.Add(CentipedeSheet);

	UPROPERTY(DefaultComponent)
	UCentipedeLavaResponseComponent LavaResponseComponent;

	UPROPERTY(DefaultComponent)
	UCentipedeLavaIntoleranceComponent LavaIntoleranceComponent;
	
	UPROPERTY(DefaultComponent)
	UCentipedeDrinkingEffectComponent DrinkingEffectComponent;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComponent;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;

	UPROPERTY(DefaultComponent)
	UHazeMeshPoseDebugComponent PoseDebugComp;

	UPROPERTY(DefaultComponent)
	UTemporalLogScrubbableVisible VisibleScrubbableComp;
#endif

	// VO Actors to allow the centepede to talk with two different voices
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ACentipedeVoActor> VoActorMomClass;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ACentipedeVoActor VoActorMom;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ACentipedeVoActor> VoActorDadClass;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ACentipedeVoActor VoActorDad;

	// Body
	UPROPERTY()
	TSubclassOf<UCentipedeSegmentComponent> SegmentClass;

	UPROPERTY(NotEditable, BlueprintHidden)
	TArray<UCentipedeSegmentComponent> Segments;

	UPROPERTY(NotEditable, BlueprintHidden)
	TArray<FCentipedeSegmentConstraint> Constraints;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(NotEditable, BlueprintHidden)
	private TPerPlayer<FCentipedeBodyPlayerWorldUpOverride> PlayerWorldUps;

	private TInstigated<ECollisionResponse> InstigatedPlayerCollisionResponse;
	default InstigatedPlayerCollisionResponse.SetDefaultValue(ECollisionResponse::ECR_Block);

	TPerPlayer<FVector> PlayerMovementInput;

	/**
	 * On each side of the centipede end there are three bones that we
	 * want to add to the body, but we don't want to modify their transforms
	 * because animation takes care of that. This magic number ensures we
	 * can use them as read-only.
	 */
	const uint SpecialBoneCount = 3;

	// Spine has 19 but leaving hip bones outside
	const uint BodySize = 17;

	const float GravityMagnitude = 980;

	private TInstigated<FVector> InstigatedGravityOverride;
	default InstigatedGravityOverride.SetDefaultValue(FVector::UpVector * GravityMagnitude);

	// Blocks network body replication
	private TInstigated<bool> InstigatedBodyReplicationBlock;
	default InstigatedBodyReplicationBlock.SetDefaultValue(false);

	private bool bDead = false;

	access CentipedeBody = private, UCentipedeBodyMovementCapability;
	bool bJustTeleported = false;

	bool bBodyInheritsActorMovement = false;
	bool bWasControlledByCutsceneLastFrame = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CreateSegments();
		CreateConstraints();
		SanctuaryCentipedeDevToggles::Centipede.MakeVisible();

		// Spawn and attach VO Actors
		VoActorMom = SpawnActor(VoActorMomClass, bDeferredSpawn = true);
		VoActorMom.MakeNetworked(this, n"CentipedeVoMom");
		FinishSpawningActor(VoActorMom);
		VoActorMom.AttachToComponent(Mesh, n"FrontCharacterRoot", EAttachmentRule::SnapToTarget);

		VoActorDad = SpawnActor(VoActorDadClass, bDeferredSpawn = true);
		VoActorDad.MakeNetworked(this, n"CentipedeVoDad");
		FinishSpawningActor(VoActorDad);
		VoActorDad.AttachToComponent(Mesh, n"BackCharacterRoot", EAttachmentRule::SnapToTarget);
	}

	// We could add a map loop, but seeing the bones makes this clearer
	void CreateSegments()
	{
		{
			UCentipedeSegmentComponent Segment = Cast<UCentipedeSegmentComponent>(CreateComponent(SegmentClass, n"GreenHead"));
			Segment.bIsHead = true;
			Segment.SegmentIndex = Segments.Num();
			Segment.AttachTo(Mesh, n"GreenHead", EAttachLocation::SnapToTarget);
			Segments.Add(Segment);
		}

		{
			UCentipedeSegmentComponent Segment = Cast<UCentipedeSegmentComponent>(CreateComponent(SegmentClass, n"GreenSpine1"));
			Segment.bIsHeadBody = true;
			Segment.SegmentIndex = Segments.Num();
			Segment.AttachTo(Mesh, n"GreenSpine1", EAttachLocation::SnapToTarget);
			Segments.Add(Segment);
		}

		/**
		 * Skipping GreenSpine
		 */

		{
			UCentipedeSegmentComponent Segment = Cast<UCentipedeSegmentComponent>(CreateComponent(SegmentClass, n"FrontHips"));
			Segment.bIsHeadBody = true;
			Segment.bIsMasterJoint = true;
			Segment.SegmentIndex = Segments.Num();
			Segment.AttachTo(Mesh, n"FrontHips", EAttachLocation::SnapToTarget);
			Segments.Add(Segment);
		}

		// Do middle body segments
		for (uint i = SpecialBoneCount; i < BodySize - SpecialBoneCount; i++)
		{
			UCentipedeSegmentComponent BodySegment = Cast<UCentipedeSegmentComponent>(CreateComponent(SegmentClass, FName("Segment" + (i - SpecialBoneCount + 1))));
			BodySegment.SegmentIndex = Segments.Num();
			Segments.Add(BodySegment);
		}

		{
			UCentipedeSegmentComponent Segment = Cast<UCentipedeSegmentComponent>(CreateComponent(SegmentClass, n"BackHips"));
			Segment.SegmentIndex = Segments.Num();
			Segment.bIsHeadBody = true;
			Segment.bIsMasterJoint = true;
			Segment.AttachTo(Mesh, n"BackHips", EAttachLocation::SnapToTarget);
			Segments.Add(Segment);
		}

		/**
		 * Skipping BlueSpine
		 */

		{
			UCentipedeSegmentComponent Segment = Cast<UCentipedeSegmentComponent>(CreateComponent(SegmentClass, n"BlueSpine1"));
			Segment.SegmentIndex = Segments.Num();
			Segment.bIsHeadBody = true;
			Segment.AttachTo(Mesh, n"BlueSpine1", EAttachLocation::SnapToTarget);
			Segments.Add(Segment);
		}

		{
			UCentipedeSegmentComponent Segment = Cast<UCentipedeSegmentComponent>(CreateComponent(SegmentClass, n"BlueHead"));
			Segment.SegmentIndex = Segments.Num();
			Segment.bIsHead = true;
			Segment.AttachTo(Mesh, n"BlueHead", EAttachLocation::SnapToTarget);
			Segments.Add(Segment);
		}
	}

	void CreateConstraints()
	{
		for (uint i = 0; i < BodySize - 1; i++)
		{
			FCentipedeSegmentConstraint Constraint;
			Constraint.Start = Segments[i];
			Constraint.End = Segments[i + 1];
			Constraints.Add(Constraint);
		}
	}

	void KillCentipede()
	{
		bDead = true;
	}

	// Snaps body segments to their ideal locations. Should be called on 1st gameplay frame.
	void ResetBody()
	{
		Segments[0].WorldLocation = Centipede::GetHeadPlayer().ActorLocation;
		Segments.Last().WorldLocation = Centipede::GetTailPlayer().ActorLocation;

		for (uint i = 1; i < SpecialBoneCount; i++)
		{
			UCentipedeSegmentComponent HeadSegment = Segments[i];
			FVector Location = Centipede::GetHeadPlayer().ActorLocation - Centipede::GetHeadPlayer().ActorForwardVector * Centipede::SegmentRadius * i * 2;
			HeadSegment.WorldLocation = Location;
			HeadSegment.WorldLocation = Location;

			UCentipedeSegmentComponent TailSegment = Segments.Last(i);
			Location = Centipede::GetTailPlayer().ActorLocation - Centipede::GetTailPlayer().ActorForwardVector * Centipede::SegmentRadius * i * 2;
			TailSegment.WorldLocation = Location;
			TailSegment.WorldLocation = Location;

			// Debug::DrawDebugSphere(HeadSegment.WorldLocation, Centipede::SegmentRadius *1., 12, FLinearColor::Green, 3, 0);
			// Debug::DrawDebugSphere(TailSegment.WorldLocation, Centipede::SegmentRadius *1., 12, FLinearColor::Green, 3, 0);
		}

		FVector StartLocation = Segments[2].WorldLocation - Centipede::GetHeadPlayer().ActorForwardVector * Centipede::SegmentRadius * 2;
		FVector EndLocation = Segments.Last(2).WorldLocation - Centipede::GetTailPlayer().ActorForwardVector * Centipede::SegmentRadius * 2;
		FVector BackwardVector = -(Centipede::GetHeadPlayer().ActorForwardVector + Centipede::GetTailPlayer().ActorForwardVector).GetSafeNormal();
		FVector Offset = BackwardVector * 30.0;

		for (uint i = SpecialBoneCount; i < BodySize - SpecialBoneCount; i++)
		{
			float Alpha = float(i - SpecialBoneCount) / float(BodySize - SpecialBoneCount * 2 - 1);

			FVector StraightLocation = Math::EaseInOut(StartLocation, EndLocation, Alpha, 2);

			Alpha = Math::Sin(Alpha * PI) * 10;

			FVector SplineOffset = Math::Lerp(FVector::ZeroVector, Offset, Alpha);
			FVector SegmentLocation = StraightLocation + SplineOffset;

			UCentipedeSegmentComponent Segment = Segments[i];
			Segment.SetWorldLocation(SegmentLocation);
			Segment.PreviousLocation = SegmentLocation;

			// Debug::DrawDebugSphere(Segment.WorldLocation, Centipede::SegmentRadius *1.5, 12, FLinearColor::Yellow, 3, 0);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerRespawned(AHazePlayerCharacter Player)
	{
		bDead = false;
		bJustTeleported = true;
	}

	void ApplyPlayerWorldUp(AHazePlayerCharacter Player, FVector WorldUp, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		// PlayerWorldUps[Player].WorldUpOverride.Apply(WorldUp, Instigator, Priority);
		PlayerWorldUps[Player].ApplyWorldUpOverride(WorldUp);
	}

	void ClearPlayerWorldUp(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		// PlayerWorldUps[Player].WorldUpOverride.Clear(Instigator);
		PlayerWorldUps[Player].ClearWorldUpOverride();
	}

	FVector GetPlayerWorldUp(AHazePlayerCharacter Player) const
	{
		return PlayerWorldUps[Player].GetWorldUp();
	}

	void ApplyDisableCollisionWithPlayer(FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		InstigatedPlayerCollisionResponse.Apply(ECollisionResponse::ECR_Overlap, Instigator, Priority);
	}

	void ClearDisableCollisionWithPlayer(FInstigator Instigator)
	{
		InstigatedPlayerCollisionResponse.Clear(Instigator);
	}

	void ApplyGravityOverride(FVector GravityOverride, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		InstigatedGravityOverride.Apply(GravityOverride, this);
	}

	void ClearGravityOverride(FInstigator Instigator)
	{
		InstigatedGravityOverride.Clear(Instigator);
	}

	void ApplyBodyReplicationBlock(FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		InstigatedBodyReplicationBlock.Apply(true, Instigator, Priority);
	}

	void ClearBodyReplicationBlock(FInstigator Instigator)
	{
		InstigatedBodyReplicationBlock.Clear(Instigator);
	}

	bool IsBodyReplicationBlocked() const
	{
		return InstigatedBodyReplicationBlock.Get();
	}

	FVector GetGravity()
	{
		return InstigatedGravityOverride.Get();
	}

	float GetBodyLength() const
	{
		return BodySize * Segments.Last().BoundsRadius;
	}

	float GetPlayerAngleRelativeToBody(AHazePlayerCharacter Player, uint SegmentResolution)
	{
		FVector PreviousForward = Player.ActorForwardVector;

		uint Offset = SpecialBoneCount;

		float TotalProjection = 0.0;
		float DirectionMultiplier = Player.Player == Centipede::HeadHazePlayer ? -1.0 : 1.0;

		for (uint i = 0; i < SegmentResolution ; i++)
		{
			auto Segment = Player.Player == Centipede::HeadHazePlayer ? Segments[i + Offset] : Segments.Last(i + Offset);
			TotalProjection += PreviousForward.DotProduct(Segment.ForwardVector.ConstrainToPlane(Player.MovementWorldUp) * DirectionMultiplier);

			// PreviousForward = Segment.ForwardVector;
		}

		TotalProjection /= SegmentResolution;

		float Angle = Math::RadiansToDegrees(Math::Acos(TotalProjection));
		return Angle;
	}


	FVector GetNeckJointLocationForPlayer(EHazePlayer Player) const
	{
		return GetSlaveSegmentForPlayer(Player, 0).WorldLocation;
	}

	UCentipedeSegmentComponent GetSlaveSegmentForPlayer(EHazePlayer Player, uint Index) const
	{
		if (Player == Centipede::HeadHazePlayer)
			return Segments[SpecialBoneCount + Index];

		return Segments.Last(SpecialBoneCount + Index);
	}

	// Eman TODO: Make nicer
	TArray<FVector> GetBodyLocations() const
	{
		TArray<FVector> Locations;
		for (auto Segment : Segments)
			Locations.Add(Segment.WorldLocation);

		return Locations;
	}

	// 0 is this player's location and 1 is other player's
	FVector GetLocationAtBodyFractionForHeadPlayer(float Fraction, EHazePlayer HeadPlayer) const
	{
		float RealSegmentIndex = Segments.Num() * Fraction;
		float SegmentFraction = Math::Frac(RealSegmentIndex);

		int SegmentIndex = Math::Clamp(Math::FloorToInt(RealSegmentIndex), 0, Segments.Num() - 1);
		FVector SegmentLocation;
		if (HeadPlayer == EHazePlayer::Mio)
		{
			int NextSegmentIndex = Math::Min(SegmentIndex + 1, Segments.Num() - 1);
			SegmentLocation = Math::Lerp(Segments[SegmentIndex].WorldLocation, Segments[NextSegmentIndex].WorldLocation, SegmentFraction);
		}
		else
		{
			int NextSegmentIndex = Math::Min(SegmentIndex + 1, Segments.Num() - 1);
			SegmentLocation = Math::Lerp(Segments.Last(SegmentIndex).WorldLocation, Segments.Last(NextSegmentIndex).WorldLocation, SegmentFraction);
		}

		return SegmentLocation;
	}

	bool IsDead() const
	{
		return bDead;
	}
}