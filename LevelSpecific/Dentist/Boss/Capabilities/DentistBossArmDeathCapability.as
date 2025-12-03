// A Tyko Special ;)
class UDentistBossLeftArmDeathCapability : UDentistBossArmDeathCapability { default bLeftArm = true; }
class UDentistBossRightArmDeathCapability : UDentistBossArmDeathCapability { default bLeftArm = false; }

class UDentistBossArmDeathCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	UDentistBossSettings Settings;
	
	bool bLeftArm = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = TListedActors<ADentistBoss>().GetSingle();
		Settings = UDentistBossSettings::GetSettings(Dentist);
		Dentist.SkelMesh.HideBoneByName(n"LeftCableBase", EPhysBodyOp::PBO_Term);
		Dentist.SkelMesh.HideBoneByName(n"RightCableBase", EPhysBodyOp::PBO_Term);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(bLeftArm
		&& Dentist.LeftHandHealthComp.IsDead())
			return true;

		if(!bLeftArm
		&& Dentist.RightHandHealthComp.IsDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bLeftArm
		&& Dentist.LeftHandHealthComp.IsDead())
			return false;

		if(!bLeftArm
		&& Dentist.RightHandHealthComp.IsDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FDentistBossEffectHandlerOnGrabberDestroyedParams EffectParams;
		if(bLeftArm)
		{
			if(Dentist.bRightArmDestroyed)
				Dentist.OnSecondArmLost.Broadcast();
			else
				Dentist.OnFirstArmLost.Broadcast();

			EffectParams.ExplosionLocation = Dentist.LeftHandWeakpointMesh.WorldLocation;
			EffectParams.SparkAttachRoot = Dentist.SkelMesh;
			auto ArmTransform = Dentist.SkelMesh.GetBoneTransform(n"LeftLowerArm");
			EffectParams.UpperArmLocation = ArmTransform.Location;
			EffectParams.ArmExplodeRotation = FRotator::MakeFromXZ(ArmTransform.Rotation.UpVector, ArmTransform.Rotation.ForwardVector);
			EffectParams.SparkAttachSocketName = n"LeftLowerArm";
			Dentist.LeftHandHealthBarComp.HideHealthBar();
			Dentist.bLeftArmDestroyed = true;
			Dentist.LeftArmCablePhysicsAlpha = 1.0;
			Dentist.SkelMesh.HideBoneByName(n"LeftLowerArm", EPhysBodyOp::PBO_Term);
			Dentist.SkelMesh.UnHideBoneByName(n"LeftCableBase");
			Dentist.SkelMesh.SetPhysicsAsset(Dentist.LeftArmDestroyedPhysAsset);
			Dentist.ToggleHandWeakpointHittable(false, true);
			Dentist.LeftHandWeakpointEffect.Deactivate();
			// Dentist.LeftHandWeakpointSpotlightComp.AddComponentVisualsBlocker(this);
			// Dentist.LeftHandWeakpointGodrayComp.AddComponentVisualsBlocker(this);
			Dentist.bPreviousArmDestroyedWasLeft = true;
			Dentist.LeftHandBiteTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);

			for(auto Player : Game::Players)
			{
				Player.PlayWorldCameraShake(Settings.ArmExplosionCameraShake, this, Dentist.LeftHandWeakpointMesh.WorldLocation, 0.0, 2000.0, 1.0);
				Player.PlayForceFeedback(Settings.ArmExplosionRumble, false, true, this);
			}
		}
		else
		{
			if(Dentist.bLeftArmDestroyed)
				Dentist.OnSecondArmLost.Broadcast();
			else
				Dentist.OnFirstArmLost.Broadcast();

			EffectParams.ExplosionLocation = Dentist.RightHandWeakpointMesh.WorldLocation;
			EffectParams.SparkAttachRoot = Dentist.SkelMesh;
			auto ArmTransform = Dentist.SkelMesh.GetBoneTransform(n"RightLowerArm");
			EffectParams.UpperArmLocation = ArmTransform.Location;
			EffectParams.ArmExplodeRotation = FRotator::MakeFromXZ(ArmTransform.Rotation.UpVector, ArmTransform.Rotation.ForwardVector);
			EffectParams.SparkAttachSocketName = n"RightLowerArm";
			Dentist.RightHandHealthBarComp.HideHealthBar();
			Dentist.bRightArmDestroyed = true;
			Dentist.RightArmCablePhysicsAlpha = 1.0;
			Dentist.SkelMesh.HideBoneByName(n"RightLowerArm", EPhysBodyOp::PBO_Term);
			Dentist.SkelMesh.UnHideBoneByName(n"RightCableBase");
			Dentist.SkelMesh.SetPhysicsAsset(Dentist.RightArmDestroyedPhysAsset);
			Dentist.ToggleHandWeakpointHittable(false, false);
			Dentist.RightHandWeakpointEffect.Deactivate();
			// Dentist.RightHandWeakpointSpotlightComp.AddComponentVisualsBlocker(this);
			// Dentist.RightHandWeakpointGodrayComp.AddComponentVisualsBlocker(this);
			Dentist.bPreviousArmDestroyedWasLeft = false;
			Dentist.RightHandBiteTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);

			for(auto Player : Game::Players)
			{
				Player.PlayWorldCameraShake(Settings.ArmExplosionCameraShake, this, Dentist.RightHandWeakpointMesh.WorldLocation, 0.0, 2000.0, 1.0);
				Player.PlayForceFeedback(Settings.ArmExplosionRumble, false, true, this);
			}
		}

		Dentist.TakeDamage(Settings.TotalHealthPerArm);
		UDentistBossEffectHandler::Trigger_OnGrabberDestroyed(Dentist, EffectParams);
		Dentist.bDenturesDestroyedHand = true;
		
		auto Dentures = Cast<ADentistBossToolDentures>(Dentist.Tools[EDentistBossTool::Dentures]);
		if(Dentures.ControllingPlayer.IsSet()
		&& !Dentures.ControllingPlayer.Value.HasControl())
			Dentures.ExplodeWithArm();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(bLeftArm)
			Dentist.bLeftArmDestroyed = false;
		else
			Dentist.bRightArmDestroyed = false;
	}
};