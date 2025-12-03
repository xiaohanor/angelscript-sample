class UTundraFairyFootstepAudioTraceCapability : UHazePlayerCapability
{
	default DebugCategory = n"Audio";
	default TickGroup = EHazeTickGroup::Audio;

	UTundraPlayerShapeshiftingComponent ShapeshiftComp;
	UHazeMovementComponent MoveComp;
	UPlayerMovementAudioComponent PlayerAudioMoveComp;
	UPlayerFootstepTraceComponent TraceComp;

	private FFootstepTrace LeftFootTrace;
	private FFootstepTrace RightFootTrace;

	TMap<EFootType, FVector> TrackedFootLocations;

	AHazeActor Fairy;
	USkeletalMeshComponent FairyMesh;

	FVector CachedPlayerLocation;	

	UPROPERTY(EditDefaultsOnly)
	UAudioPlayerFootTraceSettings FootTraceSettings = nullptr;

	AHazeActor TreeGuardian;
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		PlayerAudioMoveComp = UPlayerMovementAudioComponent::Get(Player);
		TraceComp = UPlayerFootstepTraceComponent::Get(Player);

		Fairy = UTundraPlayerFairyComponent::Get(Player).FairyActor;
		FairyMesh = ShapeshiftComp.GetMeshForShapeType(ETundraShapeshiftShape::Small);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!IsFairy())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(IsFairy())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(FootTraceSettings != nullptr)
			Player.ApplySettings(FootTraceSettings, this);

		PlayerAudioMoveComp.RequestBlockDefaultPlayerMovement(this);

		// FPlayerFootstepTraceData& LeftFootTraceData = TraceComp.GetTraceData(EFootType::Left);
		// InitializeFootData(LeftFootTraceData);

		// FPlayerFootstepTraceData& RightFootTraceData = TraceComp.GetTraceData(EFootType::Right);
		// InitializeFootData(RightFootTraceData);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsByInstigator(this);
		PlayerAudioMoveComp.UnRequestBlockDefaultPlayerMovement(this);
	}

	FVector GetTraceFrameStartPos(const FPlayerFootstepTraceData& InTraceData)
	{
		return FairyMesh.GetSocketLocation(InTraceData.Settings.SocketName);
	}

	FVector GetTraceFrameEndPos(const FPlayerFootstepTraceData& InTraceData, const float InTraceLength)
	{	
		FVector Direction;
		if(InTraceData.Settings.WorldTarget != nullptr)
		{
			Direction = (InTraceData.Settings.WorldTarget.GetWorldLocation() - InTraceData.Start).GetSafeNormal();
		}
		else
		{
			const FRotator TraceRot = FairyMesh.GetSocketRotation(InTraceData.Settings.SocketName);
			Direction = TraceRot.ForwardVector;
		}

		return InTraceData.Start - Direction * -InTraceLength;
	}

	float GetScaledTraceLength(FPlayerFootstepTraceData& InFootstepTraceData)
	{
		const float NormalizedSpeed = MoveComp.GetVelocity().Size() / InFootstepTraceData.Settings.MaxVelo;
		const float Alpha = Math::Pow(NormalizedSpeed, 2.0);
		const float ScaledLength = Math::Lerp(InFootstepTraceData.Settings.MinLength, InFootstepTraceData.Settings.MaxLength, Alpha);
		return ScaledLength;
	}

	bool ValidateFootFrameVelo(FPlayerFootstepTraceData& InFootstepTraceData)
	{
		FVector CachedLocation;
		if(!TrackedFootLocations.Find(InFootstepTraceData.Foot, CachedLocation))
			return false;

		const float VerticalDelta = InFootstepTraceData.Start.Z - CachedLocation.Z;

		const FVector PlayerVelo = Player.GetActorLocation() - CachedPlayerLocation;
		InFootstepTraceData.Velo = (InFootstepTraceData.Start - CachedLocation) - PlayerVelo;

		// Has the foot moved enough?
		if(Math::IsNearlyZero(VerticalDelta, InFootstepTraceData.Settings.MinRequiredVelo))
			return false;
		
		// Has the foot to much upwards velocity to invalidate a new footstep?
		float WorldUpDot = TraceComp.MoveComp.WorldUp.GetSafeNormal().DotProduct(InFootstepTraceData.Velo.GetSafeNormal());

		if(WorldUpDot > 0.5)		
		{
			if(!InFootstepTraceData.Trace.bGrounded)
				InFootstepTraceData.Trace.bPerformed = true;
		}

		return true;		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// FPlayerFootstepTraceData& LeftFootTraceData = TraceComp.GetTraceData(EFootType::Left);
		// FPlayerFootstepTraceData& RightFootTraceData = TraceComp.GetTraceData(EFootType::Right);

		// EvaluateFootstepTraceData(LeftFootTraceData);
		// EvaluateFootstepTraceData(RightFootTraceData);	

		// TrackedFootLocations.FindOrAdd(EFootType::Left) = LeftFootTraceData.Start;
		// TrackedFootLocations.FindOrAdd(EFootType::Right) = RightFootTraceData.Start;

		// CachedPlayerLocation = Player.GetActorLocation();
		
		if(IsDebugActive())
		{
			auto Mesh = ShapeshiftComp.GetMeshForShapeType(ETundraShapeshiftShape::Small);

			const FVector LeftFootLoc = Mesh.GetSocketLocation(MovementAudio::TundraMonkey::LeftFootSocketName);
			const FRotator LeftFootRot = Mesh.GetSocketRotation(MovementAudio::TundraMonkey::LeftFootSocketName);

			const FVector LeftFootTraceEnd = LeftFootLoc + (LeftFootRot.ForwardVector * FootTraceSettings.Left.MinLength);

			const FVector RightFootLoc = Mesh.GetSocketLocation(MovementAudio::TundraMonkey::RightFootSocketName);
			const FRotator RightFootRot = Mesh.GetSocketRotation(MovementAudio::TundraMonkey::RightFootSocketName);

			const FVector RightFootTraceEnd = RightFootLoc + (RightFootRot.ForwardVector * FootTraceSettings.Right.MinLength);

			Debug::DrawDebugCylinder(LeftFootLoc, LeftFootTraceEnd, FootTraceSettings.Left.SphereTraceRadius, 12, FLinearColor::Red);
			Debug::DrawDebugCylinder(RightFootLoc, RightFootTraceEnd, FootTraceSettings.Right.SphereTraceRadius, 12, FLinearColor::Red);
		}
	}

	void EvaluateFootstepTraceData(FPlayerFootstepTraceData& InFootstepTraceData)
	{
		// We only track plants
		if(EvaluateTrace(InFootstepTraceData) && InFootstepTraceData.Hit.bBlockingHit)	
		{	
			if(!CanPerformFootstep(InFootstepTraceData))
				return;
	
			FPlayerFootstepParams FootstepParams;	

			UPhysicalMaterial PhysMat = nullptr;
		
			FHazeTraceSettings TraceSettings = TraceComp.InitTraceSettings();
			PhysMat = AudioTrace::GetPhysMaterialFromHit(InFootstepTraceData.Hit, TraceSettings);	
			InFootstepTraceData.LastPhysMat = PhysMat;		
			
			//FootstepParams.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(PhysMat.AudioAsset);				
		
			UTundraPlayerFairyEffectHandler::Trigger_OnFootstepTrace_Plant(Fairy, FootstepParams);	
			QueryCooldowns(InFootstepTraceData);
		}	
	}

	bool EvaluateTrace(FPlayerFootstepTraceData& InFootstepTraceData)
	{
		// Reset performed-flag
		InFootstepTraceData.Trace.bPerformed = false;

		// Get trace bounds from foot
		InFootstepTraceData.Start = GetTraceFrameStartPos(InFootstepTraceData);

		// // If foot hasn't moved, or moved in opposite direction of ground, bail
		// if(!ValidateFootFrameVelo(InFootstepTraceData))
		// 	return false;

		// Get Foot Trace Length	
		const float TraceLength = GetScaledTraceLength(InFootstepTraceData);

		InFootstepTraceData.End = GetTraceFrameEndPos(InFootstepTraceData, TraceLength);

		if(IsDebugActive())
			Debug::DrawDebugLine(InFootstepTraceData.Start, InFootstepTraceData.End, FLinearColor::Red);
		
		return TraceComp.PerformFootTrace_Sphere(InFootstepTraceData, InFootstepTraceData.Settings.SphereTraceRadius, bDebug = IsDebugActive());		
	}	

	private bool CanPerformFootstep(FPlayerFootstepTraceData& TraceData)
	{
		return Time::GetRealTimeSince(TraceData.PlantTriggerTimeStamp) >= TraceData.Settings.TriggerCooldown;		
	}

	private void QueryCooldowns(FPlayerFootstepTraceData& TraceData)
	{
		if(TraceData.Trace.bGrounded)
		{
			TraceData.PlantTriggerTimeStamp = Time::GetRealTimeSeconds();		
		}	
	}

	private FPlayerFootstepTraceData& GetOtherFoot(const FPlayerFootstepTraceData& InTraceData)
	{
		if(InTraceData.Foot == EFootType::Left)
			return TraceComp.GetTraceData(EFootType::Right);
		
		return TraceComp.GetTraceData(EFootType::Right);
	}

	void InitializeFootData(FPlayerFootstepTraceData& InFootData)
	{
		InFootData.PlantTriggerTimeStamp = InFootData.Settings.TriggerCooldown;
		InFootData.ReleaseTriggerTimeStamp = InFootData.Settings.TriggerCooldown;

		InFootData.Trace.bGrounded = false;
		InFootData.Trace.bPerformed = false;
	}

	bool IsFairy() const
	{
		return ShapeshiftComp.GetCurrentShapeType() == ETundraShapeshiftShape::Small;
	}
}