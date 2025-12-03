class UIslandOverseerPeekBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	UIslandOverseerVisorComponent VisorComp;
	UIslandOverseerPeekBombLauncherComponent Launcher;
	UAnimInstanceIslandOverseer AnimInstance;

	bool bStartedPeek;
	bool bEndedPeek;	
	AHazeCharacter Character;
	float EndTime;

	FVector OriginalLocation;
	FVector TargetLocation;
	FHazeAcceleratedVector AccLocation;
	float PeekDistance = 600;

	int Attacks;
	int MaxAttacks = 6;
	FHazeAcceleratedFloat AccAimYaw;
	AHazePlayerCharacter Target;
	float AimAlpha;
	float AttackTime;
	float AttackInterval = 1;
	bool StartAttack;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Character = Cast<AHazeCharacter>(Owner);
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		VisorComp = UIslandOverseerVisorComponent::GetOrCreate(Owner);
		Launcher = UIslandOverseerPeekBombLauncherComponent::Get(Owner);
		AnimInstance = Cast<UAnimInstanceIslandOverseer>(Character.Mesh.AnimInstance);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate()) 
			return true;
		if(Owner.IsCapabilityTagBlocked(n"Peek"))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		VisorComp.Open();
		bStartedPeek = false;
		bEndedPeek = false;
		UIslandOverseerEventHandler::Trigger_OnPeekStart(Owner);
		OriginalLocation = Owner.ActorLocation;
		AccLocation.SnapTo(OriginalLocation);
		Attacks = 0;
		AnimComp.RequestFeature(FeatureTagIslandOverseer::Peek, SubTagIslandOverseerPeek::Start, EBasicBehaviourPriority::Medium, this);
		AccAimYaw.SnapTo(0);

		if(Target == nullptr)
			SetTarget(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		VisorComp.Close();
		UIslandOverseerEventHandler::Trigger_OnPeekEnd(Owner);
		UIslandOverseerEventHandler::Trigger_OnPeekAttackEnd(Owner);
		Owner.ActorLocation = OriginalLocation;
		Cooldown.Set(0.1);
		AnimComp.AimYaw.Clear(this);
	}

	private void SetAttackAlpha(bool bStart)
	{
		if(Target.IsPlayerDead())
			SetTarget(Target.OtherPlayer);

		FVector NeckLocation = Character.Mesh.GetSocketLocation(n"Neck");
		FVector Direction;
		Direction = (Target.ActorCenterLocation - NeckLocation).GetSafeNormal2D(Owner.ActorForwardVector);
		float Alpha = Math::Clamp(Direction.GetAngleDegreesTo(FVector::DownVector) / 30, 0, 1);
		if(Owner.ActorRightVector.DotProduct(Target.ActorCenterLocation - Owner.ActorLocation) > 0)
			Alpha *= -1;
		AimAlpha = Alpha;

		if(HasControl() && bStart)
			CrumbStartAttack(Alpha, Target.ActorCenterLocation);
	}

	private void SetTarget(AHazePlayerCharacter _Target)
	{
		if(HasControl())
			CrumbSetTarget(_Target);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetTarget(AHazePlayerCharacter _Target)
	{
		Target = _Target;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStartAttack(float _AimAlpha, FVector _TargetLocation)
	{
		AimAlpha = _AimAlpha;
		TargetLocation = _TargetLocation;
		StartAttack = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Target == nullptr)
			return;

		if(ActiveDuration < AnimInstance.PeekStart.Sequence.PlayLength)
		{
			AccLocation.AccelerateTo(OriginalLocation + Owner.ActorForwardVector * PeekDistance, AnimInstance.PeekStart.Sequence.PlayLength, DeltaTime);
			Owner.ActorLocation = AccLocation.Value;
			return;
		}

		if(!bStartedPeek)
		{
			bStartedPeek = true;
			FIslandOverseerEventHandlerOnPeekAttackStartData Data = FIslandOverseerEventHandlerOnPeekAttackStartData();
			Data.LaunchLocation = Launcher.WorldLocation;
			UIslandOverseerEventHandler::Trigger_OnPeekAttackStart(Owner, Data);
			AttackTime = Time::GameTimeSeconds;
		}

		if(Attacks >= MaxAttacks)
		{
			if(!bEndedPeek)
			{
				bEndedPeek = true;
				VisorComp.Close();
				AnimComp.RequestSubFeature(SubTagIslandOverseerPeek::End, this);
				UIslandOverseerEventHandler::Trigger_OnPeekAttackEnd(Owner);
				EndTime = Time::GameTimeSeconds;
			}

			if(Time::GetGameTimeSince(EndTime) > AnimInstance.PeekEnd.Sequence.PlayLength)
				DeactivateBehaviour();

			AccLocation.AccelerateTo(OriginalLocation, AnimInstance.PeekEnd.Sequence.PlayLength, DeltaTime);
			Owner.ActorLocation = AccLocation.Value;

			return;
		}

		if(StartAttack)
		{
			AttackTime = Time::GameTimeSeconds;
			Attack();
		}
		else
		{
			if(Time::GetGameTimeSince(AttackTime) > AttackInterval && Target != nullptr)
				SetAttackAlpha(true);
			else
				SetAttackAlpha(false);
		}

		AccAimYaw.AccelerateTo(AimAlpha, AttackInterval, DeltaTime);
		AnimComp.AimYaw.Apply(AccAimYaw.Value, this);
	}

	private void Attack()
	{
		FVector LaunchLocation = Math::ProjectPositionOnInfiniteLine(Launcher.WorldLocation, Character.ActorForwardVector, TargetLocation);
		FVector ProjectedDir = (TargetLocation - LaunchLocation).VectorPlaneProject(Owner.ActorForwardVector);
		FVector AttackLocation = Math::ProjectPositionOnInfiniteLine(LaunchLocation, ProjectedDir, TargetLocation);
		FVector LaunchDir = (AttackLocation - LaunchLocation).GetSafeNormal();

		int ProjectileAmount = 1;
		float AngleOffset = 0;
		float Angle = -AngleOffset;

		for(int i = 0; i < ProjectileAmount; i++)
		{
			FVector AngledLaunchDir = LaunchDir.RotateAngleAxis(Angle, Owner.ActorForwardVector);
			Launch(AngledLaunchDir, LaunchLocation);
			Angle += AngleOffset;
		}

		FIslandOverseerEventHandlerOnPeekAttackLaunchData Data;
		Data.LaunchLocation = LaunchLocation;
		UIslandOverseerEventHandler::Trigger_OnPeekAttackLaunch(Owner, Data);
		
		Attacks++;
		StartAttack = false;
		if(!Target.OtherPlayer.IsPlayerDead())
			SetTarget(Target.OtherPlayer);
	}

	private void Launch(FVector Dir, FVector LaunchLocation)
	{
		UBasicAIProjectileComponent Projectile = Launcher.Launch(Dir * 500);
		Projectile.Owner.SetActorLocation(LaunchLocation);
	}
}