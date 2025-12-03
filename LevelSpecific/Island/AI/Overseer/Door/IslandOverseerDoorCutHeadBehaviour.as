
class UIslandOverseerDoorCutHeadBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	AAIIslandOverseer Overseer;
	UIslandOverseerSettings Settings;
	UAnimInstanceIslandOverseer AnimInstance;
	UIslandOverseerDoorComponent DoorComp;
	UIslandOverseerVisorComponent VisorComp;
	bool bDoorClosed;
	bool bReverse;
	bool bResisted;
	
	float ImpulseMioTime = 0;
	float ImpulseZoeTime = 0;

	bool bInitialImpulse;
	float ImpulseDuration = 0.1;
	float ImpulseTimer;
	bool bImpulseExpired;
	float CutHeadAnimTime;
	float EndAnimTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Overseer = Cast<AAIIslandOverseer>(Owner);
		AnimInstance = Cast<UAnimInstanceIslandOverseer>(Overseer.Mesh.AnimInstance);
		DoorComp = UIslandOverseerDoorComponent::Get(Owner);
		DoorComp.OnDoorImpulse.AddUFunction(this, n"OnDoorImpulse");
		VisorComp = UIslandOverseerVisorComponent::GetOrCreate(Owner);
		CutHeadAnimTime = AnimInstance.DoorCutHeadDecapitate.Sequence.GetAnimNotifyTime(UIslandOverseerDoorCutHeadCutAnimNotify);
		EndAnimTime = AnimInstance.DoorCutHeadDecapitate.Sequence.GetAnimNotifyTime(UIslandOverseerDoorCutHeadEndAnimNotify);
	}

	UFUNCTION()
	private void OnDoorImpulse(AHazeActor Instigator)
	{
		if(!IsActive())
			return;
		if(bDoorClosed)
			return;

		if(Instigator == Game::Mio)
			ImpulseMioTime = Time::GameTimeSeconds;
		else
			ImpulseZoeTime = Time::GameTimeSeconds;

		if(Math::Abs(ImpulseMioTime - ImpulseZoeTime) < 0.3)
		{
			if(!bInitialImpulse)
			{
				bInitialImpulse = true;

				if(DoorComp.bDoorCutHead)
				{
					UIslandOverseerDoorEventHandler::Trigger_OnDoorsStartMovingResisted(Owner, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));

					// SoundDef on doors
					for(auto& Door : DoorComp.Doors)
					{
						UIslandOverseerDoorEventHandler::Trigger_OnDoorsStartMovingResisted(Door, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
					}
				}
				else
				{
					UIslandOverseerDoorEventHandler::Trigger_OnDoorsStartMovingDamage(Owner, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));

					// SoundDef on doors
					for(auto& Door : DoorComp.Doors)
					{
						UIslandOverseerDoorEventHandler::Trigger_OnDoorsStartMovingDamage(Door, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
					}
				}
			}

			if(HasControl() && ImpulseTimer <= 0)
				CrumbSetImpulseTimer();

			return;
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetImpulseTimer()
	{
		ImpulseTimer = ImpulseDuration;
		bImpulseExpired = false;
		DoorComp.CutHeadPlayRate = 0.5;
		for(AIslandSidescrollerBossDoor Door : DoorComp.Doors)
			Door.ResistEffect.NiagaraComp.Activate();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(bDoorClosed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		DoorComp.CutHeadPlayRate = 0;
		DoorComp.bDoorClosing = true;
		Owner.BlockCapabilities(n"OpenDoorAttack", Owner);
		DoorComp.bDoorCutHead = true;
		Overseer.HeadPlayerCollision.CollisionProfileName = CollisionProfile::BlockOnlyPlayerCharacter;
		bImpulseExpired = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		DoorComp.bDoorClosing = false;
		DoorComp.OnDoorClosed.Broadcast();
		DoorComp.ReclosingCompleted();
		DoorComp.OnHeadCutStop.Broadcast();
		DoorComp.CutHeadPlayRate = 0;
		UIslandOverseerDoorEventHandler::Trigger_OnDoorsStopMovingHeadCut(Owner, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
		Overseer.HeadPlayerCollision.CollisionProfileName = CollisionProfile::NoCollision;

		// SoundDef on doors
		for(auto& Door : DoorComp.Doors)
		{
			UIslandOverseerDoorEventHandler::Trigger_OnDoorsStopMovingHeadCut(Door, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
		}

		for(AIslandSidescrollerBossDoor Door : DoorComp.Doors)
			Door.ResistEffect.NiagaraComp.Deactivate();

		DoorComp.DisableCutHeadState();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bDoorClosed)
		{
			TArray<FHazePlayingAnimationData> Animations;
			Overseer.Mesh.GetCurrentlyPlayingAnimations(Animations);
			for (FHazePlayingAnimationData AnimData : Animations)
			{
				if(AnimData.Sequence != AnimInstance.DoorCutHeadDecapitate.Sequence)
					continue;
				if(AnimData.CurrentPosition > EndAnimTime - SMALL_NUMBER)
					DeactivateBehaviour();
			}
			return;	
		}

		if(!bResisted && DoorComp.bResist)
		{
			bResisted = true;
			DoorComp.bDoorCutHead = false;
			UIslandOverseerDoorEventHandler::Trigger_OnDoorsStopMovingResisted(Owner, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
			UIslandOverseerDoorEventHandler::Trigger_OnDoorsStartMovingDamage(Owner, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));

			// SoundDef on doors
			for(auto& Door : DoorComp.Doors)
			{
				UIslandOverseerDoorEventHandler::Trigger_OnDoorsStopMovingResisted(Door, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
				UIslandOverseerDoorEventHandler::Trigger_OnDoorsStartMovingDamage(Door, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
			}	

			Overseer.OnCutHeadStart.Broadcast();
			Overseer.CutHeadStartFx.Activate();
		}

		if(DoorComp.bCut)
			return;

		if(HasControl())
		{
			TArray<FHazePlayingAnimationData> Animations;
			Overseer.Mesh.GetCurrentlyPlayingAnimations(Animations);
			for (FHazePlayingAnimationData AnimData : Animations)
			{
				if(AnimData.Sequence != AnimInstance.DoorCutHeadDecapitate.Sequence)
					continue;
				if(AnimData.CurrentPosition > CutHeadAnimTime - SMALL_NUMBER)
				{
					CrumbStartCut();
					return;
				}
			}
		}
		else
		{
			// On remote make sure that we don't advance the animation past the cut head moment until control decided that it has been cut
			TArray<FHazePlayingAnimationData> Animations;
			Overseer.Mesh.GetCurrentlyPlayingAnimations(Animations);
			for (FHazePlayingAnimationData AnimData : Animations)
			{
				if(AnimData.Sequence != AnimInstance.DoorCutHeadDecapitate.Sequence)
					continue;
				if(AnimData.CurrentPosition > CutHeadAnimTime - SMALL_NUMBER)
					DoorComp.CutHeadPlayRate = 0;
			}
		}

		ImpulseTimer -= DeltaTime;
		if(ImpulseTimer <= 0 && !bImpulseExpired)
		{
			DoorComp.CutHeadPlayRate = 0;
			bImpulseExpired = true;
			if(DoorComp.bDoorCutHead)
			{
				UIslandOverseerDoorEventHandler::Trigger_OnDoorsStopMovingResisted(Owner, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));

				// SoundDef on doors
				for(auto& Door : DoorComp.Doors)
				{
					UIslandOverseerDoorEventHandler::Trigger_OnDoorsStopMovingResisted(Door, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
				}

			}
			else
			{
				UIslandOverseerDoorEventHandler::Trigger_OnDoorsStopMovingDamage(Owner, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));

				// SoundDef on doors
				for(auto& Door : DoorComp.Doors)
				{
					UIslandOverseerDoorEventHandler::Trigger_OnDoorsStopMovingDamage(Door, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
				}
			}

			for(AIslandSidescrollerBossDoor Door : DoorComp.Doors)
				Door.ResistEffect.NiagaraComp.Deactivate();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartCut()
	{
		DoorComp.bCut = true;
		bDoorClosed = true;
		DoorComp.CutHeadPlayRate = 1;
		DoorComp.OnHeadCutStart.Broadcast();
		Overseer.Mesh.CollisionProfileName = n"BlockAllDynamic";
		DoorComp.OnDoorClosed.Broadcast();

		Overseer.Mesh.SetSkeletalMeshAsset(DoorComp.HeadCutMesh);
		Overseer.HeadCutFx.Activate();
		for(int i = 0; i < DoorComp.HeadCutMesh.Materials.Num(); i++)
		{
			FSkeletalMaterial Material = DoorComp.HeadCutMesh.Materials[i];
			Overseer.Mesh.SetMaterial(i, Material.MaterialInterface);
		}
		Overseer.Mesh.SetColorParameterValueOnMaterialIndex(3, n"EmissiveTint", FLinearColor::Black);
		Overseer.Mesh.SetColorParameterValueOnMaterialIndex(6, n"EmissiveColor", FLinearColor::Black);
		Overseer.Mesh.SetColorParameterValueOnMaterialIndex(7, n"EmissiveColor", FLinearColor::Black);
		
		UIslandOverseerDoorEventHandler::Trigger_OnDoorsStopMovingResisted(Owner, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
		UIslandOverseerDoorEventHandler::Trigger_OnDoorsStartMovingHeadCut(Owner, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));

		// SoundDef on doors
		for(auto& Door : DoorComp.Doors)
		{
			UIslandOverseerDoorEventHandler::Trigger_OnDoorsStopMovingResisted(Door, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
			UIslandOverseerDoorEventHandler::Trigger_OnDoorsStartMovingHeadCut(Door, FIslandOverseerEventHandlerDoorData(DoorComp.Doors));
		}

		Overseer.OnCutHeadSuccess.Broadcast();
		Overseer.CutHeadStartFx.Deactivate();

		for(AIslandSidescrollerBossDoor Door : DoorComp.Doors)
			Door.ResistEffect.NiagaraComp.Deactivate();
	}
}