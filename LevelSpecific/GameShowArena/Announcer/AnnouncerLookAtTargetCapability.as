class UGameShowArenaAnnouncerLookAtTargetCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"LookAt");

	default TickGroup = EHazeTickGroup::LastMovement;
	AGameShowArenaAnnouncer Announcer;
	UGameShowArenaAnnouncerBodyComponent BodyComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Announcer = Cast<AGameShowArenaAnnouncer>(Owner);
		BodyComp = UGameShowArenaAnnouncerBodyComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Announcer.bLookAtTarget)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Announcer.bLookAtTarget)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AHazeActor Target;
		if (Announcer.TargetOverride.Get() != nullptr)
			Target = Announcer.TargetOverride.Get();
		else
			Target = Announcer.TargetPlayer;
		
		if (Announcer.bHasJustSnappedBody)
		{
			Announcer.bHasJustSnappedBody = false;
			BodyComp.CopyValuesFromAnnouncer();
			return;
		}

		CalculateBaseRotation(Target, bSnap = true);
		CalculateArmExtensions(Target, bSnap = true);
		CalculateArm8Location(Target, bSnap = true);
		CalculateBodyRotation(Target, bSnap = true);
		CalculateHeadTransform(Target, bSnap = true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	void CalculateArm8Location(AHazeActor Target, float DeltaTime = 0, bool bSnap = false)
	{
		FVector DesiredArm8Location = BodyComp.GetDesiredArm8Location(Target);
		if (!bSnap)
		{
			float AccelerateDuration = 3;
			if (ActiveDuration < 2)
				AccelerateDuration = 5;

			BodyComp.AccArm8ControlLocation.AccelerateTo(DesiredArm8Location, AccelerateDuration, DeltaTime);
		}
		else
		{
			BodyComp.AccArm8ControlLocation.SnapTo(DesiredArm8Location);
		}

		Announcer.IKArm8CtrlLocation = BodyComp.AccArm8ControlLocation.Value;
	}

	void CalculateBaseRotation(AHazeActor Target, float DeltaTime = 0, bool bSnap = false)
	{
		float Angle = BodyComp.GetDesiredAngleToTarget(Target);

		if (!bSnap)
		{
			float AccelerateDuration = 3;
			if (ActiveDuration < 2)
				AccelerateDuration = 0;
			BodyComp.AccBaseRotation.AccelerateTo(Angle, AccelerateDuration, DeltaTime);
		}
		else
		{
			BodyComp.AccBaseRotation.SnapTo(Angle);
		}

		Announcer.BaseTwist = BodyComp.AccBaseRotation.Value;
	}

	void CalculateBodyRotation(AHazeActor Target, float DeltaTime = 0, bool bSnap = false)
	{
		FRotator BodyRotation = BodyComp.GetDesiredBodyRotationToTarget(Target);
		if (!bSnap)
		{
			float AccelerateDuration = 3;
			if (ActiveDuration < 2)
				AccelerateDuration = 5;

			BodyComp.AccBodyRotation.AccelerateTo(BodyRotation, AccelerateDuration, DeltaTime);
		}
		else
		{
			BodyComp.AccBodyRotation.SnapTo(BodyRotation);
		}

		Announcer.BodyRotation = BodyComp.AccBodyRotation.Value.Yaw;
	}

	void CalculateHeadTransform(AHazeActor Target, float DeltaTime = 0, bool bSnap = false)
	{
		float SpringStiffness = 50;
		if (ActiveDuration < 2)
		{
			SpringStiffness = 10;
		}
		FTransform DesiredTransform = BodyComp.GetDesiredHeadTransform(Target);
		if (!bSnap)
		{
			BodyComp.AccArm13ControlLocation.SpringTo(DesiredTransform.Location, SpringStiffness, 1.0, DeltaTime);
			BodyComp.AccHeadControlRotation.SpringTo(DesiredTransform.Rotator(), SpringStiffness, 1.0, DeltaTime);
		}
		else
		{
			BodyComp.AccArm13ControlLocation.SnapTo(DesiredTransform.Location);
			BodyComp.AccHeadControlRotation.SnapTo(DesiredTransform.Rotator());
		}
		Announcer.IKArm13Ctrl = FTransform(BodyComp.AccHeadControlRotation.Value, BodyComp.AccArm13ControlLocation.Value);
	}

	void CalculateArmExtensions(AHazeActor Target, float DeltaTime = 0, bool bSnap = false)
	{
		float Noise = Math::PerlinNoise1D(ActiveDuration) * 45;
		auto PistonData = BodyComp.GetDesiredPistonExtensions(Target, Noise);
		if (!bSnap)
		{
			float AccelerateDuration = 1.0;
			if (ActiveDuration < 2)
			{
				AccelerateDuration = 3;
			}

			BodyComp.AccLowerExtend.AccelerateTo(PistonData.LowerPistonExtension, AccelerateDuration, DeltaTime);
			BodyComp.AccUpperExtend.AccelerateTo(PistonData.UpperPistonExtension, AccelerateDuration, DeltaTime);
		}
		else
		{
			BodyComp.AccLowerExtend.SnapTo(PistonData.LowerPistonExtension);
			BodyComp.AccUpperExtend.SnapTo(PistonData.UpperPistonExtension);
		}

		Announcer.LowerPistonExtend = BodyComp.AccLowerExtend.Value;
		Announcer.UpperPistonExtend = BodyComp.AccUpperExtend.Value;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AHazeActor Target;
		if (Announcer.TargetOverride.Get() != nullptr)
			Target = Announcer.TargetOverride.Get();
		else
			Target = Announcer.TargetPlayer;

		CalculateBaseRotation(Target, DeltaTime);
		CalculateArmExtensions(Target, DeltaTime);
		CalculateArm8Location(Target, DeltaTime);
		CalculateBodyRotation(Target, DeltaTime);
		CalculateHeadTransform(Target, DeltaTime);
	}
};