
class UIslandBeamTurretronTrackTargetBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	FVector InitialUpDir;
	AAIIslandBeamTurretron BeamTurretron;

	UIslandBeamTurretronSettings Settings;

	bool bShouldPredict = false;
	bool bHasSetCurrentTargetLoc = false;
	FVector CurrentTargetLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		InitialUpDir = Owner.ActorUpVector;
		BeamTurretron = Cast<AAIIslandBeamTurretron>(Owner);
		Settings = UIslandBeamTurretronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasGeometryVisibleTarget(TargetOffset = FVector(0,0, -79.0)))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasGeometryVisibleTarget(TargetOffset = FVector(0,0, -79.0)))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	}

	float DelayTime = 0.5;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < DelayTime)
			return;

		TargetDirectly(DeltaTime);
	}

	private void TargetDirectly(float DeltaTime)
	{
        FVector TargetLoc = TargetComp.Target.ActorCenterLocation;        
        FVector Dir = (TargetLoc - BeamTurretron.FocusLocation).GetSafeNormal();
		
		// Ease rotation for holder
		FVector CurrentDir = BeamTurretron.MeshHolderPivot.WorldRotation.Vector().GetSafeNormal();
		const float RotationSpeed = 10;
		float Delta = RotationSpeed * DeltaTime;		
		FVector NewDir = CurrentDir.SlerpTowards(Dir, Delta);

		BeamTurretron.MeshHolderPivot.SetWorldRotation(FRotator::MakeFromZX(InitialUpDir, NewDir));
		CurrentDir = BeamTurretron.MeshHolderPivot.WorldRotation.Vector().GetSafeNormal(); // gets constrained before calculating vertical angle.

		// Ease rotation for gun
		FVector CurrentGunDir = BeamTurretron.MeshTurretPivot.WorldRotation.Vector();
		const float HolderRotationSpeed = 10;
		float HolderDelta = HolderRotationSpeed * DeltaTime;
		CurrentGunDir = CurrentGunDir.SlerpTowards(Dir, HolderDelta);

 		// Calculate the angle in radians between CurrentGunDir and CurrentDir
        float VerticalAngle = Math::Acos(CurrentGunDir.DotProduct(CurrentDir));
        // Convert to degrees
        float VerticalAngleDegrees = Math::RadiansToDegrees(VerticalAngle);
        // Clamp the angle to desired maximum pitch
        const float MaxPitchAngle = 60.0;
        VerticalAngleDegrees = Math::Min(VerticalAngleDegrees, MaxPitchAngle);

        FVector WorldUp = FVector::UpVector;
		float Sign = Math::Sign(CurrentGunDir.DotProduct(WorldUp));
        CurrentGunDir = CurrentDir.RotateAngleAxis(Sign * VerticalAngleDegrees, CurrentDir.CrossProduct(WorldUp));

		FVector RightVector = BeamTurretron.MeshTurretPivot.GetRightVector();
		BeamTurretron.MeshTurretPivot.SetWorldRotation(FRotator::MakeFromYX(RightVector, CurrentGunDir));
	}

	private void TargetPredictively(float DeltaTime)
	{
			FVector TargetLoc = TargetComp.Target.ActorCenterLocation;	
			if (!bHasSetCurrentTargetLoc)
				CurrentTargetLoc = TargetLoc;
			bHasSetCurrentTargetLoc = true;

			// Predict movement
			FVector TargetVelocity = Cast<AHazePlayerCharacter>(TargetComp.Target).GetRawLastFrameTranslationVelocity();
			TargetVelocity.Z = 0; // Prevents overcompensating while player is jumping
			float Distance = TargetLoc.Distance(Owner.ActorCenterLocation);
			TargetLoc += TargetVelocity.GetSafeNormal() * (Distance * (TargetVelocity.Size() / Settings.LaunchSpeed));
			
			const float LerpSpeed = 600.0;
			CurrentTargetLoc += (TargetLoc - CurrentTargetLoc).GetSafeNormal() * DeltaTime * LerpSpeed;
#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(CurrentTargetLoc, 10, LineColor = FLinearColor::Green);		
			Debug::DrawDebugSphere(TargetLoc, 10, LineColor = FLinearColor::Red);
		}			
#endif
			
			FVector Dir = (CurrentTargetLoc - Owner.ActorCenterLocation).GetSafeNormal();
			BeamTurretron.MeshTurretPivot.SetWorldRotation(FRotator::MakeFromZX(InitialUpDir, Dir));

			FVector RightVector = BeamTurretron.MeshTurretPivot.GetRightVector();
			BeamTurretron.MeshTurretPivot.SetWorldRotation(FRotator::MakeFromYX(RightVector, Dir));
	}


	UFUNCTION(DevFunction)
	void ToggleMovementPrediction()
	{
		bShouldPredict = !bShouldPredict;
		PrintToScreen("MovementPrediction: " + bShouldPredict, 3.0);
	}

	UFUNCTION(DevFunction)
	void ToggleDebugFlag()
	{
		Owner.bHazeEditorOnlyDebugBool = !Owner.bHazeEditorOnlyDebugBool;
		PrintToScreen("DebugFlag: " + Owner.bHazeEditorOnlyDebugBool, 3.0);
	}
}
