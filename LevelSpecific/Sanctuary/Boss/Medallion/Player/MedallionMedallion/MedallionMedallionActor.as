asset MedallionMedallionSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UMedallionMedallionCutsceneVisibleCapability);
	Capabilities.Add(UMedallionMedallionHoverCapability);
	Capabilities.Add(UMedallionMedallionOnChestSocketCapability);
	Capabilities.Add(UMedallionMedallionOnHighfiveSocketCapability);
	Capabilities.Add(UMedallionMedallionInsideCapability);
	Capabilities.Add(UMedallionMedallionVisibleCapability);
	Capabilities.Add(UMedallionMedallionScalingCapability);
	Capabilities.Add(UMedallionMedallionStateCapability);
}

enum EMedallionMedallionState
{
	Hidden,
	OnSocketChest,
	OnSocketHighfive,
	HoverTowardsOther,
	HoverTowardsInsideDummy,
	CutsceneControlled,
}

event void FMedallionSocketedChangeSignature();

class AMedallionMedallionActor : AHazeActor
{
	access CapabilityAccess = private, * (readonly), 
		UMedallionMedallionHoverCapability,
		UMedallionMedallionOnChestSocketCapability,
		UMedallionMedallionOnHighfiveSocketCapability,
		UMedallionMedallionInsideCapability,
		UMedallionMedallionStateCapability;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RemoveOffsetsBetweenStatesRoot;

	UPROPERTY(DefaultComponent, Attach = RemoveOffsetsBetweenStatesRoot)
	UHazeOffsetComponent Offset;

	UPROPERTY(DefaultComponent, Attach = Offset)
	UHazeSkeletalMeshComponentBase CinematicSkelMeshBase;

	UPROPERTY(DefaultComponent, Attach = CinematicSkelMeshBase, AttachSocket = "Base")
	USceneComponent MedallionRoot;

	UPROPERTY(DefaultComponent, Attach = MedallionRoot)
	USceneComponent MedallionAttachWireRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ButtonMashAttachComp;

	UPROPERTY(EditInstanceOnly)
	AMedallionMedallionActor OtherMedallionActor;

	UPROPERTY(DefaultComponent, Attach = MedallionRoot)
	UStaticMeshComponent WireMesh;

	UPROPERTY()
	FName ChestAttachSocket = n"MedallionSocket";

	UPROPERTY()
	FName LeftAttachSocket = n"MedallionSocketLeft";

	UPROPERTY()
	FName RightAttachSocket = n"MedallionSocketRight";

	UPROPERTY()
	FName MioHighfiveAttachSocket = n"LeftAttach";
	UPROPERTY()
	FName ZoeHighfiveAttachSocket = n"RightAttach";

	float AddedNecklaceLength = 10.0;
	FHazeAcceleratedFloat AccNecklaceLength;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(MedallionMedallionSheet);

	UPROPERTY(DefaultComponent)
	UTemporalLogActorDetailsLoggerComponent LoggingComp;

	UPROPERTY()
	EHazePlayer TargetPlayer = EHazePlayer::Mio;
	AHazePlayerCharacter Player;

	UPROPERTY(EditAnywhere, Interp)
	AHazeSkeletalMeshActor CutscenePlayer;

	UPROPERTY(EditAnywhere, Interp)
	bool bWiresEnabled = true;

	access : CapabilityAccess float Opacity;
	access : CapabilityAccess bool bMergReady = false;
	access : CapabilityAccess bool bMerged = false;
	access : CapabilityAccess EMedallionMedallionState MedallionState;

	TArray<FInstigator> VisibleInstigators;

	FMedallionSocketedChangeSignature OnSocketed;
	FMedallionSocketedChangeSignature OnSocketedStop;

	UPROPERTY(EditAnywhere, Interp)
	float MedallionWireCutsceneLength0 = 50;

	UPROPERTY(EditAnywhere, Interp)
	float MedallionWireCutsceneLength1 = 50;

	bool bHasAttached = false;

	const FName VisualsBlocker = n"VisualsBlocker";

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Game::GetPlayer(TargetPlayer);

		UMedallionPlayerComponent MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		MedallionComp.MedallionActor = this;
		UMedallionPlayerComponent OtherMedallionComp = UMedallionPlayerComponent::GetOrCreate(Player.OtherPlayer);
		if (OtherMedallionComp.MedallionActor != nullptr)
		{
			OtherMedallionComp.MedallionActor.OtherMedallionActor = this;
			OtherMedallionActor = OtherMedallionComp.MedallionActor;
		}
		AddActorVisualsBlock(VisualsBlocker);

		// Reset it on start
		WireMesh.SetVectorParameterValueOnMaterials(n"MaterialTransform_Location", FVector::ZeroVector);
		WireMesh.SetVectorParameterValueOnMaterials(n"MaterialTransform1_Location", FVector::ZeroVector);
		WireMesh.SetVectorParameterValueOnMaterials(n"MaterialTransform2_Location", FVector::ZeroVector);
		WireMesh.SetScalarParameterValueOnMaterials(n"Length0", 0);
		WireMesh.SetScalarParameterValueOnMaterials(n"Length1", 0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (AttachParentActor != nullptr || Player.bIsControlledByCutscene || this.bIsControlledByCutscene)
			bHasAttached = true;
		
		if (!bHasAttached)
		{
			bHasAttached = true;
			AttachToComponent(Player.Mesh, ChestAttachSocket, EAttachmentRule::SnapToTarget);
		}

		UpdateNecklace(DeltaSeconds);
		ButtonMashAttachComp.SetWorldLocation(ActorLocation + FVector::UpVector * 50.0);

		if (SanctuaryMedallionHydraDevToggles::Draw::Amulet.IsEnabled())
		{
			if (AttachParentActor != nullptr)
			{
				Debug::DrawDebugArrow(ActorLocation, AttachParentActor.ActorLocation, LineColor = ColorDebug::Yellow, bDrawInForeground = true);
				AHazePlayerCharacter AttacedPlayer = Cast<AHazePlayerCharacter>(AttachParentActor);
				if (AttacedPlayer != nullptr)
				{
					FVector SocketLocation = AttacedPlayer.Mesh.GetSocketLocation(AttachParentSocketName);
					Debug::DrawDebugArrow(AttachParentActor.ActorLocation, SocketLocation, LineColor = ColorDebug::Leaf, bDrawInForeground = true);
				}
				Debug::DrawDebugArrow(RemoveOffsetsBetweenStatesRoot.WorldLocation, ActorLocation, LineColor = ColorDebug::Magenta, bDrawInForeground = true);
				Debug::DrawDebugArrow(MedallionRoot.WorldLocation, RemoveOffsetsBetweenStatesRoot.WorldLocation, LineColor = ColorDebug::Cyan, bDrawInForeground = true);
			}
			else
				Debug::DrawDebugArrow(ActorLocation, MedallionRoot.WorldLocation, bDrawInForeground = true);

			Debug::DrawDebugString(ActorLocation, "State: " + MedallionState);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnSequencerEvaluation(FHazeSequencerEvalParams EvalParams)
	{
		if(EvalParams.bIsPreview)
		{
			UpdateNecklaceCutscenePreview(0.5);
		}
	}

	// Editor only
	private void UpdateNecklaceCutscenePreview(float DeltaSeconds)
	{
		if(CutscenePlayer == nullptr)
			return;

		FVector LeftLocation = CutscenePlayer.Mesh.GetSocketLocation(n"LeftShoulder");
		if(CutscenePlayer.Mesh.DoesSocketExist(LeftAttachSocket))
			LeftLocation = CutscenePlayer.Mesh.GetSocketLocation(LeftAttachSocket);
		
		FVector RightLocation = CutscenePlayer.Mesh.GetSocketLocation(n"RightShoulder");
		if(CutscenePlayer.Mesh.DoesSocketExist(RightAttachSocket))
			RightLocation = CutscenePlayer.Mesh.GetSocketLocation(RightAttachSocket);
		
		FVector MedallionLocation = MedallionAttachWireRoot.WorldLocation;

		if(bWiresEnabled)
		{
			WireMesh.SetVectorParameterValueOnMaterials(n"MaterialTransform_Location", LeftLocation);
			WireMesh.SetVectorParameterValueOnMaterials(n"MaterialTransform1_Location", RightLocation);
			WireMesh.SetVectorParameterValueOnMaterials(n"MaterialTransform2_Location", MedallionLocation);
		}
		else
		{
			WireMesh.SetVectorParameterValueOnMaterials(n"MaterialTransform_Location", FVector::ZeroVector);
			WireMesh.SetVectorParameterValueOnMaterials(n"MaterialTransform1_Location", FVector::ZeroVector);
			WireMesh.SetVectorParameterValueOnMaterials(n"MaterialTransform2_Location", FVector::ZeroVector);
		}

		WireMesh.SetScalarParameterValueOnMaterials(n"Length0", MedallionWireCutsceneLength0);
		WireMesh.SetScalarParameterValueOnMaterials(n"Length1", MedallionWireCutsceneLength1);
	}

	private void UpdateNecklace(float DeltaSeconds)
	{
		bool bFoundSockets = true;
		if(!Player.Mesh.DoesSocketExist(LeftAttachSocket))
			bFoundSockets = false;
		if(!Player.Mesh.DoesSocketExist(RightAttachSocket))
			bFoundSockets = false;
		
		FVector LeftLocation = Player.Mesh.GetSocketLocation(LeftAttachSocket);
		FVector RightLocation = Player.Mesh.GetSocketLocation(RightAttachSocket);
		FVector MedallionLocation = MedallionAttachWireRoot.WorldLocation;
		if(bFoundSockets && bWiresEnabled)
		{
			WireMesh.SetVectorParameterValueOnMaterials(n"MaterialTransform_Location", LeftLocation);
			WireMesh.SetVectorParameterValueOnMaterials(n"MaterialTransform1_Location", RightLocation);
			WireMesh.SetVectorParameterValueOnMaterials(n"MaterialTransform2_Location", MedallionLocation);
		}
		else
		{
			WireMesh.SetVectorParameterValueOnMaterials(n"MaterialTransform_Location", FVector::ZeroVector);
			WireMesh.SetVectorParameterValueOnMaterials(n"MaterialTransform1_Location", FVector::ZeroVector);
			WireMesh.SetVectorParameterValueOnMaterials(n"MaterialTransform2_Location", FVector::ZeroVector);
		}

		if(Player.bIsParticipatingInCutscene)
		{
			WireMesh.SetScalarParameterValueOnMaterials(n"Length0", MedallionWireCutsceneLength0);
			WireMesh.SetScalarParameterValueOnMaterials(n"Length1", MedallionWireCutsceneLength1);
		}
		else
		{

			float NecklaceLengthMultiplier = 1.0;
			const float Long = 1.0;
			const float Short = 0.7;
			switch (MedallionState)
			{
				case EMedallionMedallionState::Hidden:
				case EMedallionMedallionState::OnSocketChest:
				NecklaceLengthMultiplier = Short;
				break;
				case EMedallionMedallionState::OnSocketHighfive:
				NecklaceLengthMultiplier = Long;
				break;
				case EMedallionMedallionState::HoverTowardsOther:
				NecklaceLengthMultiplier = Long;
				break;
				case EMedallionMedallionState::HoverTowardsInsideDummy:
				NecklaceLengthMultiplier = Long;
				break;
				case EMedallionMedallionState::CutsceneControlled:
				NecklaceLengthMultiplier = Long;
				break;
			}

			const float AverageDistanceToSocket = (LeftLocation.Distance(MedallionLocation) + RightLocation.Distance(MedallionLocation)) * 0.5 + AddedNecklaceLength;
			const float NecklaceLength = AverageDistanceToSocket * NecklaceLengthMultiplier;
			if (Math::IsNearlyEqual(AccNecklaceLength.Value, 0.0, KINDA_SMALL_NUMBER))
				AccNecklaceLength.SnapTo(NecklaceLength);
			AccNecklaceLength.AccelerateTo(NecklaceLength, 1.0, DeltaSeconds);
			WireMesh.SetScalarParameterValueOnMaterials(n"Length0", AccNecklaceLength.Value);
			WireMesh.SetScalarParameterValueOnMaterials(n"Length1", AccNecklaceLength.Value);
		}

	}

	UFUNCTION(BlueprintEvent)
	access : CapabilityAccess void BP_MedallionReunited(){}
};
