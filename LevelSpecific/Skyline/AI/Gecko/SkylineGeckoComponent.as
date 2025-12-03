event void FSkylineGeckoDamageOverturnedStartSignature();
event void FSkylineGeckoDamageOverturnedStopSignature();

class USkylineGeckoComponent : UActorComponent
{
	AHazeCharacter Character;
	UBasicAIHealthComponent HealthComp;
	UGravityWhipTargetComponent WhipTarget;
	UGravityWhipResponseComponent WhipResponse;
	TArray<UHazeCameraComponent> ConstrainCameras;
	USkylineGeckoSettings GeckoSettings;

	TInstigated<bool> bAllowBladeHits;
	default bAllowBladeHits.DefaultValue = true;

	bool bShielded = false;
	bool bThrownOff = false;
	FVector ThrownOffDirection;

	float OverturnedTime = -BIG_NUMBER;
	AHazeActor OverturningActor = nullptr;
	TOptional<FVector> OverturningDirection;

	bool bOverturned;
	FVector OverturnedLocation;
	bool bHitByThrownGecko;
	bool bCounter;
	FSkylineGeckoDamageOverturnedStartSignature OnOverturnedStart;
	FSkylineGeckoDamageOverturnedStopSignature OnOverturnedStop;

	FScenepointPerchPosition PerchPos;
	FVector ReachedGroundPosition = FVector(BIG_NUMBER);

	TInstigated<bool> bShouldConstrainAttackLeap;
	bool bIsConstrainingTarget = false;

	TInstigated<bool> bShouldLeap;
	TInstigated<bool> bIsLeaping;
	UHazeSplineComponent CurrentClimbSpline = nullptr;	
	float ClimbSplineSideOffset = 0.0;

	private TInstigated<bool> bWhipGrabEnabled;
	private TInstigated<EGravityWhipGrabMode> WhipGrabMode;

	TInstigated<bool> bCanDodge;
	float LastDodgeStartTime;

	TArray<ASkylineGeckoClimbSplineActor> ClimbSplines;

	USkylineGeckoTeam Team;

	UPROPERTY()
	UMaterialInterface HackDyingIndicatorMaterial;

	FLinearColor OriginalTelegraphTint;
	bool bTelegraph;
	float FocusOffset;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset ConstrainCameraSettings;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ConstrainCameraShake;

	UPROPERTY()
	UForceFeedbackEffect ConstrainForceFeedback;

	const FName PounceToken = n"PounceToken";
	const FName ConstrainToken = n"ConstrainToken";

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Character == nullptr)
			Initialize();
	}

	void Initialize()
	{
		if (Character != nullptr)
			return;
		Character = Cast<AHazeCharacter>(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		WhipTarget = UGravityWhipTargetComponent::Get(Owner);
		WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WhipResponse.GrabMode = WhipGrabMode.Get();
		GeckoSettings = USkylineGeckoSettings::GetSettings(Character);
		Character.GetComponentsByClass(UHazeCameraComponent, ConstrainCameras);

		Team = Cast<USkylineGeckoTeam>(Character.JoinTeam(SkylineGeckoTags::SkylineGeckoTeam, USkylineGeckoTeam));

		OverturnedLocation = Owner.ActorLocation;
		bCanDodge.SetDefaultValue(true);
		bWhipGrabEnabled.SetDefaultValue(true);
		WhipGrabMode.SetDefaultValue(EGravityWhipGrabMode::Sling);

		ClimbSplines = TListedActors<ASkylineGeckoClimbSplineActor>().Array;

		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr)
			RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");

		OriginalTelegraphTint = Character.Mesh.CreateDynamicMaterialInstance(0).GetVectorParameterValue(n"EmissiveTint");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (Team != nullptr)
			Character.LeaveTeam(SkylineGeckoTags::SkylineGeckoTeam);
	}

	void StartTelegraph()
	{
		bTelegraph = true;
	}

	void UpdateTelegraph(FLinearColor TelegraphColor, float Speed)
	{
		FLinearColor FinalColor = TelegraphColor * 150;
		if(!bTelegraph)
			return;
		float Alpha = Math::GetMappedRangeValueClamped(FVector2D(-1, 1), FVector2D(0, 1), Math::Sin(Time::GameTimeSeconds * Speed));
		FVector EaseColor = Math::EaseIn(FVector(OriginalTelegraphTint.R, OriginalTelegraphTint.G, OriginalTelegraphTint.B), FVector(FinalColor.R, FinalColor.G, FinalColor.B), Alpha, 2);
		FLinearColor Color = FLinearColor(EaseColor.X, EaseColor.Y, EaseColor.Z, 1);
		Character.Mesh.SetColorParameterValueOnMaterialIndex(0, n"EmissiveTint", Color);
	}

	void StopTelegraph()
	{
		bTelegraph = false;
		ResetEmissiveColor();
	}

	void SetEmissiveColor(FLinearColor Color)
	{
		Character.Mesh.SetColorParameterValueOnMaterialIndex(0, n"EmissiveTint", Color * 150);
	}

	void ResetEmissiveColor()
	{
		Character.Mesh.SetColorParameterValueOnMaterialIndex(0, n"EmissiveTint", OriginalTelegraphTint);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRespawn()
	{
		OverturnedLocation = Owner.ActorLocation;
		bShielded = false;
		bThrownOff = false;
		ResetOverturned();
		ReachedGroundPosition = FVector(BIG_NUMBER);
	}

	void SetOverturned()
	{
		bOverturned = true;
		OverturnedLocation = Owner.ActorLocation;
		OnOverturnedStart.Broadcast();
	}

	void ResetOverturned(bool bGrabbed = false)
	{
		bOverturned = false;
		OnOverturnedStop.Broadcast();
	}

	bool ShouldPerch(UGentlemanComponent TargetGentlemanComp)
	{
		int Perchers = TargetGentlemanComp.GetNumberOfClaimedTokens(GeckoToken::Perching);
		if (TargetGentlemanComp.IsClaimingToken(GeckoToken::Perching, Owner))
			Perchers--;
		int Grounders = TargetGentlemanComp.GetNumberOfClaimedTokens(GeckoToken::Grounded);
		if (TargetGentlemanComp.IsClaimingToken(GeckoToken::Grounded, Owner))
			Grounders--;

		// Perch when there are more geckos doing ground attacks
		if (Grounders > Perchers)
			return true;
		if (Grounders < Perchers)
			return false;

		// Same number of perchers and grounders, perch if there's at least one other grounder
		if (Grounders > 0)
			return true;

		// ... or stay on ground if waiting for attack opportunity while a percher may be preparing an attack
		if ((Perchers > 0) && IsAtGroundPosition(GeckoSettings.GroundPositioningDoneRange + 40.0))
			return false;	

		// ...or if there's been a ground attack more recently than latest perch attack
		if (TargetGentlemanComp.GetLastActionTime(GeckoTag::GroundAttack) > TargetGentlemanComp.GetLastActionTime(GeckoTag::PerchAttack))
			return true;
		return false;
	}

	bool IsAtPerch(float Radius) const
	{
		if (!PerchPos.IsValid())
			return false;
		if (!Owner.ActorLocation.IsWithinDist(PerchPos.Location, Radius))
			return false;
		if (Owner.ActorUpVector.DotProduct(PerchPos.UpVector) < 0.999)
			return false;
		return true;	
	}

	bool IsAtGroundPosition(float Radius)
	{
		if (Math::Abs(Owner.ActorLocation.Z - ReachedGroundPosition.Z) < Radius)
			return true;
		return false;
	}	

	void ApplyWhipGrab(bool bAllowed, EGravityWhipGrabMode GrabMode, FInstigator Instigator)
	{
		if (bAllowed)
			WhipTarget.Enable(Instigator);
		else
			WhipTarget.Disable(Instigator);

		WhipGrabMode.Apply(GrabMode, this);
		if (WhipResponse == nullptr)
			WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WhipResponse.GrabMode = WhipGrabMode.Get();
	}

	void ClearWhipGrab(FInstigator Instigator)
	{
		// Whiptargets can only be disabled, enabling them clears any disablement
		WhipTarget.Enable(Instigator);

		WhipGrabMode.Clear(this);
		if (WhipResponse == nullptr)
			WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WhipResponse.GrabMode = WhipGrabMode.Get();
	}

	bool IsAlignedWithSpline(FSplinePosition SplinePos) const
	{
		if (SplinePos.WorldForwardVector.DotProduct(Owner.ActorForwardVector) < 0.0)
			return false;
		return true;
	}

	ASkylineGeckoClimbSplineActor FindClosestSpline(float MaxRange) const
	{
		if (CurrentClimbSpline != nullptr)
		{
			ASkylineGeckoClimbSplineActor CurClimbSpline = Cast<ASkylineGeckoClimbSplineActor>(CurrentClimbSpline.Owner);
			if (CurClimbSpline != nullptr)
				return CurClimbSpline;
		}

		FVector OwnLoc = Character.ActorCenterLocation;
		float ClosestDistSqr = Math::Square(MaxRange);
		ASkylineGeckoClimbSplineActor BestSpline = nullptr;
		for (ASkylineGeckoClimbSplineActor Spline : ClimbSplines)
		{
			FSplinePosition SplinePos = Spline.GetSplinePositionNearWorldLocation(OwnLoc);
			float DistSqr = OwnLoc.DistSquared2D(SplinePos.WorldLocation);
			if (DistSqr > ClosestDistSqr)
				continue;
			ClosestDistSqr = DistSqr;
			BestSpline = Spline;
		}

		return BestSpline;
	}

	FSplinePosition FindClosestSplinePositionInFrontOfPlayer(AHazePlayerCharacter Player, float MaxRange) const
	{
		FSplinePosition BestSplinePos;
		if (Player == nullptr)
			return BestSplinePos;

		FVector PlayerLoc = Player.FocusLocation;
		FVector FwdDir = FRotator(0.0, Player.ViewRotation.Yaw, 0.0).ForwardVector;
		FVector OwnLoc = Character.ActorCenterLocation;
		float ClosestDistSqr = Math::Square(MaxRange);
		for (ASkylineGeckoClimbSplineActor Spline : ClimbSplines)
		{
			FSplinePosition SplinePos = Spline.GetSplinePositionNearWorldLocation(OwnLoc);
			if (FwdDir.DotProduct(SplinePos.WorldLocation - PlayerLoc) < 0.0)
				continue;
			float DistSqr = OwnLoc.DistSquared2D(SplinePos.WorldLocation);
			if (DistSqr > ClosestDistSqr)
				continue;
			ClosestDistSqr = DistSqr;
			BestSplinePos = SplinePos;
		}

		return BestSplinePos;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		// Always make sure gecko is unspawned when disabled, regardless of how it's done.
		// This is in gecko component OnActorDisabled to ensure it get's run after 
		// behaviour component OnActorDisabled
		UBasicBehaviourComponent BehaviourComp = UBasicBehaviourComponent::Get(Owner);
		if ((BehaviourComp != nullptr) && BehaviourComp.bIsSpawned)
			BehaviourComp.Unspawn();
	}
}

namespace GeckoToken
{
	const FName Perching = n"Perching";
	const FName Grounded = n"Grounded";
}

namespace GeckoTag
{
	const FName PerchAttack = n"PerchAttack";
	const FName GroundAttack = n"GroundAttack";
	const FName BlobAttack = n"BlobAttack";
	const FName DakkaAttack = n"DakkaAttack";
}