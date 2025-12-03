class UAIDebugDisplayComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	private bool bDebugSelected = false;
	private bool bDebugDisplayTarget = false; 
	private bool bDebugDisplayTeamMates = false; 
	private bool bDebugDisplayEnemies = false; 
	private bool bDebugDisplayBehaviours = false; 
	private bool bDebugDisplayCapabilities = false; 
	private bool bDebugDisplaySpawner = false;
	private bool bDebugDisplayControlSide = false;
	private bool bDebugDisplayCapsule = false;

	UHazeCapabilityComponent CapabilityComp;
	UHazeActorRespawnableComponent RespawnComp;

	AHazeActor HazeOwner;
	UHazeCapsuleCollisionComponent Capsule;
	bool bDevToggleBlockedBehaviour = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		CapabilityComp = UHazeCapabilityComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		AHazeCharacter CharOwner = Cast<AHazeCharacter>(Owner);
		Capsule = (CharOwner != nullptr) ? CharOwner.CapsuleComponent : UHazeCapsuleCollisionComponent::Get(Owner); 

		AIDevtoggles::DebugPose.BindOnChanged(this, n"OnDebugPoseDevToggle");
		AIDevtoggles::MainDebugFlag.BindOnChanged(this, n"OnMainDebugFlagDevtoggle");
		AIDevtoggles::ShowBehaviours.BindOnChanged(this, n"OnShowActiveBehavioursDevToggle");
		AIDevtoggles::ShowCapabilities.BindOnChanged(this, n"OnShowActiveCapabilitiesDevToggle");
		AIDevtoggles::ShowTarget.BindOnChanged(this, n"OnShowTargetDevToggle");
		AIDevtoggles::ShowControlSide.BindOnChanged(this, n"OnShowControlSideDevToggle");
		AIDevtoggles::ShowCapsule.BindOnChanged(this, n"OnShowCapsuleDevToggle");
		AIDevtoggles::BlockBehaviour.BindOnChanged(this, n"OnBlockBehaviourDevToggle");
		AIDevtoggles::AICategory.MakeVisible();	
		OnDebugPoseDevToggle(AIDevtoggles::DebugPose.IsEnabled());
		OnMainDebugFlagDevtoggle(AIDevtoggles::MainDebugFlag.IsEnabled());
		OnShowActiveBehavioursDevToggle(AIDevtoggles::ShowBehaviours.IsEnabled());
		OnShowActiveCapabilitiesDevToggle(AIDevtoggles::ShowCapabilities.IsEnabled());
		OnShowTargetDevToggle(AIDevtoggles::ShowTarget.IsEnabled());
		OnShowControlSideDevToggle(AIDevtoggles::ShowControlSide.IsEnabled());
		OnShowCapsuleDevToggle(AIDevtoggles::ShowCapsule.IsEnabled());
		OnBlockBehaviourDevToggle(AIDevtoggles::BlockBehaviour.IsEnabled());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ShouldTick())
		{
			SetComponentTickEnabled(false);
			return;
		}

		if (bDebugSelected)
		{
			FVector Origin;
			FVector Extents;
			Owner.GetActorBounds(true, Origin, Extents);
			Origin += Owner.ActorUpVector * (Extents.Z + 20.0); 
			float Scale = Math::Max(Extents.Z, 100.0);			
			Debug::DrawDebugArrow(Origin + Owner.ActorUpVector * Scale * 0.5, Origin, Scale * 0.65, FLinearColor::Yellow, Scale * 0.05);
			Debug::DrawDebugPoint(Origin + Owner.ActorUpVector * Scale * 0.5, 5.0, FLinearColor::Yellow, 0.0, true);
		}

		if (bDebugDisplayTarget)
		{
			UBasicAITargetingComponent TargetComp = UBasicAITargetingComponent::Get(Owner);
			if (TargetComp != nullptr && TargetComp.HasValidTarget())
			{
				Debug::DrawDebugLine(Owner.ActorLocation, TargetComp.Target.ActorLocation, FLinearColor::Red * 0.75, 10);				
			}
		}

		if (bDebugDisplayEnemies)
		{
			FVector Origin = Owner.ActorLocation + Owner.ActorUpVector * 100.0;
			TArray<AHazeActor> Enemies = AIVoiceOver::GetClosestEnemies(Owner);
			float Size = 2.0;
			for (AHazeActor Enemy : Enemies)
			{
				if (Enemy == nullptr)
					continue;
				Debug::DrawDebugLine(Origin, Enemy.ActorLocation, FLinearColor::Red, Size);
				float Dist = Owner.ActorLocation.Distance(Enemy.ActorLocation);
				Debug::DrawDebugString(Enemy.ActorLocation - (Enemy.ActorLocation - Origin).GetSafeNormal() * 80.0 + Enemy.ActorUpVector * 20.0, "" + Math::RoundToInt(Dist), Scale = Size);
				Size = 1.0;
			}
		}

		if (bDebugDisplayTeamMates)
		{
			FVector Origin = Owner.ActorLocation + Owner.ActorUpVector * 150.0;
			TArray<AHazeActor> TeamMates = AIVoiceOver::GetClosestFriendlies(Owner);
			float Size = 2.0;
			int i = 0;
			for (AHazeActor TeamMate : TeamMates)
			{
				if (TeamMate == nullptr)
					continue;
				FVector TeamMateLoc = TeamMate.ActorLocation + TeamMate.ActorUpVector * 120.0;
				Debug::DrawDebugLine(Origin, TeamMateLoc, FLinearColor::Green, Size);
				float Dist = Owner.ActorLocation.Distance(TeamMate.ActorLocation);
				Debug::DrawDebugString(TeamMateLoc - (TeamMateLoc - Origin).GetSafeNormal() * 80.0 + TeamMate.ActorUpVector * 20.0, "" + Math::RoundToInt(Dist), Scale = Size * 0.75);
				Size = 1.0;
				i++;
			}
		}

		if ((bDebugDisplayBehaviours || bDebugDisplayCapabilities) && (CapabilityComp != nullptr))
		{
			FVector DrawLoc = Owner.ActorLocation + FVector(0.0, 0.0, 200.0);
			TArray<FHazeCapabilityDebugHandle> CapabilityHandles;
			CapabilityDebug::GetFilteredCapabilityDebug(CapabilityComp, FHazeCapabilityDebugFilter(), CapabilityHandles);	
			if (bDebugDisplayBehaviours)
			{
				for (FHazeCapabilityDebugHandle Handle : CapabilityHandles)
				{
					if (!Handle.IsChildCapability())
						continue;
					FHazeCapabilityDebugInfo DebugInfo;
					Handle.GetCapabilityDebugInfo(DebugInfo);
					if (!DebugInfo.bIsActive)
						continue;
					FString DebugName = DebugInfo.DisplayName;
					DebugName.RemoveFromEnd("Behaviour");
					Debug::DrawDebugString(DrawLoc, DebugName, FLinearColor::Green, 0.0, 1.3);
					DrawLoc.Z += 30.0; 
				}	
			}	
			if (bDebugDisplayCapabilities)
			{
				for (FHazeCapabilityDebugHandle Handle : CapabilityHandles)
				{
					if (Handle.IsChildCapability() || Handle.IsCompoundCapability())
						continue;
					FHazeCapabilityDebugInfo DebugInfo;
					Handle.GetCapabilityDebugInfo(DebugInfo);
					if (!DebugInfo.bIsActive)
						continue;
					FString DebugName = DebugInfo.DisplayName;
					DebugName.RemoveFromEnd("Capability");
					Debug::DrawDebugString(DrawLoc, DebugName, FLinearColor::Yellow, 0.0, 1.3);
					DrawLoc.Z += 30.0; 
				}	
			}
		}

		if (bDebugDisplaySpawner)
		{
			FVector DrawLoc = Owner.ActorLocation + FVector(0.0, 0.0, 180.0);
			if ((RespawnComp == nullptr) || (RespawnComp.SpawnParameters.Spawner == nullptr))
			{
				Debug::DrawDebugString(DrawLoc, "Not spawned by spawner.", FLinearColor::Yellow * 0.5, 0.0, 1.3);
			}
			else
			{
				AActor Spawner = Cast<AActor>(RespawnComp.SpawnParameters.Spawner);
				if (Spawner == nullptr)
					Spawner = Cast<AActor>(RespawnComp.SpawnParameters.Spawner.Outer);
				if (Spawner == nullptr)
				{
					Debug::DrawDebugString(DrawLoc, "Spawned by non-actor spawner " + Spawner.GetName(), FLinearColor::Yellow, 0.0, 1.3);
				}
				else
				{
					Debug::DrawDebugString(DrawLoc, "Spawned by " + Spawner.GetActorNameOrLabel(), FLinearColor::Yellow, 0.0, 1.3);
					Debug::DrawDebugLine(DrawLoc - FVector(0.0, 0.0, 10.0), Spawner.ActorLocation, FLinearColor::Yellow * 0.7, 5.0);
					Debug::DrawDebugSphere(Spawner.ActorLocation, 50.0, 4, FLinearColor::Yellow * 0.7, 5.0);
				}
			}
		}

		if (bDebugDisplayControlSide)
		{
			FVector DrawLoc = Owner.ActorLocation + FVector(0.0, 0.0, 220.0);
			if (HasControl())
				Debug::DrawDebugString(DrawLoc, "CONTROL", FLinearColor::Green, Scale = 1.0);
			else
				Debug::DrawDebugString(DrawLoc, "REMOTE", FLinearColor::Red, Scale = 1.0);
		}

		if (bDebugDisplayCapsule && (Capsule != nullptr))
			Debug::DrawDebugCapsule(Capsule.WorldLocation, Capsule.ScaledCapsuleHalfHeight, Capsule.ScaledCapsuleRadius, Capsule.WorldRotation, FLinearColor::Yellow, 3.0);
	}

	private bool ShouldTick() const
	{
		if (!bDebugSelected && 
			!bDebugDisplayTarget && 
			!bDebugDisplayTeamMates && 
			!bDebugDisplayEnemies &&
			!bDebugDisplayBehaviours && 
			!bDebugDisplayCapabilities && 
			!bDebugDisplayControlSide && 
			!bDebugDisplayCapsule && 
			!bDebugDisplaySpawner)
			return false;
		return true;		
	}

	bool IsDebugSelected() const
	{
		return bDebugSelected;
	}

	void SetDebugSelected()
	{
		bDebugSelected = true;
		SetComponentTickEnabled(true);
	}

	void ClearDebugSelected()
	{
		bDebugSelected = false;
	}
	
	bool IsDebugDisplayTarget() const
	{
		return bDebugDisplayTarget;
	}
	
	void SetDebugDisplayTarget()
	{
		bDebugDisplayTarget= true;
		SetComponentTickEnabled(true);
	}

	void ClearDebugDisplayTarget()
	{
		bDebugDisplayTarget = false;
	}

	void SetDebugDisplayTeamMates()
	{
		bDebugDisplayTeamMates = true;
		SetComponentTickEnabled(true);
	}

	void ClearDebugDisplayTeamMates()
	{
		bDebugDisplayTeamMates = false;
	}

	void SetDebugDisplayEnemies()
	{
		bDebugDisplayEnemies = true;
		SetComponentTickEnabled(true);
	}

	void ClearDebugDisplayEnemies()
	{
		bDebugDisplayEnemies = false;
	}

	bool IsDisplayingBehaviours() const
	{
		return bDebugDisplayBehaviours;
	}

	void SetDebugDisplayBehaviours()
	{
		bDebugDisplayBehaviours = true;
		SetComponentTickEnabled(true);
	}

	void ClearDebugDisplayBehaviours()
	{
		bDebugDisplayBehaviours = false;
	}

	bool IsDisplayingCapabilities() const
	{
		return bDebugDisplayCapabilities;
	}

	void SetDebugDisplayCapabilities()
	{
		bDebugDisplayCapabilities = true;
		SetComponentTickEnabled(true);
	}

	void ClearDebugDisplayCapabilities()
	{
		bDebugDisplayCapabilities = false;
	}

	bool IsDisplayingSpawner() const
	{
		return bDebugDisplaySpawner;
	}

	void SetDebugDisplaySpawner()
	{
		bDebugDisplaySpawner = true;
		SetComponentTickEnabled(true);
	}

	void ClearDebugDisplaySpawner()
	{
		bDebugDisplaySpawner = false;
	}

	bool IsDisplayingControlSide() const
	{
		return bDebugDisplayControlSide;
	}

	void SetDebugDisplayControlSide()
	{
		bDebugDisplayControlSide = true;
		SetComponentTickEnabled(true);
	}

	void ClearDebugDisplayControlSide()
	{
		bDebugDisplayControlSide = false;
	}

	bool IsDisplayingCapsule() const
	{
		return bDebugDisplayCapsule;
	}

	void SetDebugDisplayCapsule()
	{
		bDebugDisplayCapsule = true;
		SetComponentTickEnabled(true);
	}

	void ClearDebugDisplayCapsule()
	{
		bDebugDisplayCapsule = false;
	}

	UFUNCTION()
	private void OnDebugPoseDevToggle(bool bNewState)
	{
#if TEST
		if (bNewState)
			UHazeMeshPoseDebugComponent::GetOrCreate(Owner);
		// Never turn off...
#endif
	}

	UFUNCTION()
	private void OnMainDebugFlagDevtoggle(bool bNewState)
	{
#if EDITOR
		Owner.bHazeEditorOnlyDebugBool = bNewState;
#endif
	}

	UFUNCTION()
	private void OnShowActiveBehavioursDevToggle(bool bNewState)
	{
#if TEST
		if (bNewState)
			SetDebugDisplayBehaviours();
		else
			ClearDebugDisplayBehaviours();
#endif
	}

	UFUNCTION()
	private void OnShowActiveCapabilitiesDevToggle(bool bNewState)
	{
#if TEST
		if (bNewState)
			SetDebugDisplayCapabilities();
		else
			ClearDebugDisplayCapabilities();
#endif
	}

	UFUNCTION()
	private void OnShowTargetDevToggle(bool bNewState)
	{
#if TEST
		if (bNewState)
			SetDebugDisplayTarget();
		else
			ClearDebugDisplayTarget();
#endif
	}

	UFUNCTION()
	private void OnShowControlSideDevToggle(bool bNewState)
	{
#if TEST
		if (bNewState)
			SetDebugDisplayControlSide();
		else
			ClearDebugDisplayControlSide();
#endif
	}

	UFUNCTION()
	private void OnShowCapsuleDevToggle(bool bNewState)
	{
#if TEST
		if (bNewState)
			SetDebugDisplayCapsule();
		else
			ClearDebugDisplayCapsule();
#endif
	}

	UFUNCTION()
	private void OnBlockBehaviourDevToggle(bool bNewState)
	{
#if TEST
		if (bNewState && !bDevToggleBlockedBehaviour)
		{
			bDevToggleBlockedBehaviour = true;
			HazeOwner.BlockCapabilities(BasicAITags::Behaviour, this);
		}
		else if (!bNewState && bDevToggleBlockedBehaviour)
		{
			bDevToggleBlockedBehaviour = false;
			HazeOwner.UnblockCapabilities(BasicAITags::Behaviour, this);
		}
#endif
	}
}

namespace AIDevtoggles
{
	const FHazeDevToggleCategory AICategory = FHazeDevToggleCategory(n"AI");
	const FHazeDevToggleBool MainDebugFlag = FHazeDevToggleBool(AICategory, n"Main debug flag", "Turn on any generic debug drawing for all AIs.");
	const FHazeDevToggleBool DebugPose = FHazeDevToggleBool(AICategory, n"Debug pose", "Allow temporal log playback of character mesh pose.");
	const FHazeDevToggleBool ShowBehaviours = FHazeDevToggleBool(AICategory, n"Show behaviours", "Display which behaviours are active.");
	const FHazeDevToggleBool ShowCapabilities = FHazeDevToggleBool(AICategory, n"Show capabilities", "Display which capabilities are active (except behaviours).");
	const FHazeDevToggleBool ShowTarget = FHazeDevToggleBool(AICategory, n"Show target", "Show which actor we're currently targeting.");
	const FHazeDevToggleBool ShowControlSide = FHazeDevToggleBool(AICategory, n"Show control side", "Show green marker on control side and red on remote.");
	const FHazeDevToggleBool ShowCapsule = FHazeDevToggleBool(AICategory, n"Show capsule", "Debug draw main collision capsule.");
	const FHazeDevToggleBool BlockBehaviour = FHazeDevToggleBool(AICategory, n"Block behaviour", "Block all behaviour of AIs");
}
