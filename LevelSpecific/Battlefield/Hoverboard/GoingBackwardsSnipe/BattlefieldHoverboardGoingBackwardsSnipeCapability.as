struct FBattlefieldHoverboardGoingBackwardsSnipeActivationParams
{
	bool bActivatedByVolume = false;
}

struct FBattlefieldHoverboardGoingBackwardsSnipeDeactivateParams
{
	bool bWarningTimePassed = false;
}

class UBattlefieldHoverboardGoingBackwardsSnipeCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(n"BlockedByCutscene");
	default CapabilityTags.Add(n"BattlefieldSniper");

	UBattlefieldHoverboardComponent HoverboardComp;

	UBattlefieldHoverboardLevelRubberbandingComponent RubberbandComp;
	UBattlefieldHoverboardFreeFallingComponent FreeFallingComp;

	UBattlefieldHoverboardGoingBackwardsSnipeSettings Settings;

	float GraceTimer = 0.0;
	float TimeLastIssuedWarning = 0.0;

	bool bWarningIssued = false;
	bool bActivatedByVolume = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);

		RubberbandComp = UBattlefieldHoverboardLevelRubberbandingComponent::Get(Player);
		FreeFallingComp = UBattlefieldHoverboardFreeFallingComponent::Get(Player);
		Settings = UBattlefieldHoverboardGoingBackwardsSnipeSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBattlefieldHoverboardGoingBackwardsSnipeActivationParams& Params) const
	{
		if(FreeFallingComp.bIsFreeFalling)
			return false;

		if(!HoverboardComp.bBackwardsSnipeEnabled)
			return false;

		if (HoverboardComp.SniperVolumes.Num() > 0)
		{
			Params.bActivatedByVolume = true;
			return true;
		}

		if(IsGoingBackwards())
		{
			Params.bActivatedByVolume = false;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FBattlefieldHoverboardGoingBackwardsSnipeDeactivateParams& Params) const
	{
		if(FreeFallingComp.bIsFreeFalling)
			return true;

		if(!HoverboardComp.bBackwardsSnipeEnabled)
			return true;
		
		if(bWarningIssued
		&& Time::GetGameTimeSince(TimeLastIssuedWarning) > Settings.WarningTime)
		{
			Params.bWarningTimePassed = true;
			return true;
		}

		if(bActivatedByVolume)
		{
			if (HoverboardComp.SniperVolumes.Num() == 0)
				return true;
		}
		else
		{
			if(!IsGoingBackwards())
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBattlefieldHoverboardGoingBackwardsSnipeActivationParams Params)
	{
		bActivatedByVolume = Params.bActivatedByVolume;
		bWarningIssued = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FBattlefieldHoverboardGoingBackwardsSnipeDeactivateParams Params)
	{
		if(Params.bWarningTimePassed)
		{
			GraceTimer = 0.0;
			FBattlefieldHoverboardGoingBackwardsSnipeOnWarningIgnoredParams EventParams;
			EventParams.BoneToAttachTo = Settings.BoneToAttachTo;
			EventParams.MeshToAttachTo = Player.Mesh;
			EventParams.SnipeWorldRotation = Player.ActorTransform.TransformRotation(Settings.OffsetFromPlayer);
			UBattlefieldHoverboardGoingBackwardsSnipeEventHandler::Trigger_OnWarningIgnored(Player, EventParams);
			Player.KillPlayer();
		}
		else
		{
			UBattlefieldHoverboardGoingBackwardsSnipeEventHandler::Trigger_OnWarningTimePassed(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive()
		&& GraceTimer > 0)
		{
			GraceTimer -= DeltaTime;
			GraceTimer = Math::Max(GraceTimer, 0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(GraceTimer > Settings.GraceTime
		&& !bWarningIssued)
			IssueWarning();

		GraceTimer += DeltaTime;
	}

	bool IsGoingBackwards() const
	{
		auto SplinePos = RubberbandComp.SplinePos;
		FVector FlatSplineForward = SplinePos.WorldForwardVector.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FVector FlatPlayerForward = Player.ActorForwardVector.ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		float PlayerDotSpline = FlatPlayerForward.DotProduct(FlatSplineForward);
		if(PlayerDotSpline < 0)
			return true;

		return false;
	}

	void IssueWarning()
	{
		bWarningIssued = true;
		TimeLastIssuedWarning = Time::GameTimeSeconds;

		FBattlefieldHoverboardGoingBackwardsSnipeOnWarningIssuedParams EventParams;
		EventParams.BoneToAttachTo = Settings.BoneToAttachTo;
		EventParams.MeshToAttachTo = Player.Mesh;
		EventParams.LaserWorldRotation = Player.ActorTransform.TransformRotation(Settings.OffsetFromPlayer);
		UBattlefieldHoverboardGoingBackwardsSnipeEventHandler::Trigger_OnWarningIssued(Player, EventParams);
	}
};