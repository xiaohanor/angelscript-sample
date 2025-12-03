
class USkylineTurretTrackTargetBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	FVector InitialUpDir;
	AAISkylineTurret Turret;

	USkylineTurretSettings Settings;

	bool bShouldPredict = false;
	bool bHasSetCurrentTargetLoc = false;
	FVector CurrentTargetLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		InitialUpDir = Owner.ActorUpVector;

		Settings = USkylineTurretSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Turret = Cast<AAISkylineTurret>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bShouldPredict)
			TargetDirectly(DeltaTime);
		else
			TargetPredictively(DeltaTime);
	}

	private void TargetDirectly(float DeltaTime)
	{
		FVector TargetLoc = TargetComp.Target.ActorCenterLocation;	
			
		FVector Dir = (TargetLoc - Owner.ActorCenterLocation).GetSafeNormal();
		
		// Ease rotation for holder
		FVector CurrentDir = Turret.Mesh_Holder.WorldRotation.Vector().GetSafeNormal();
		const float RotationSpeed = 10;
		float Delta = RotationSpeed * DeltaTime;
		CurrentDir = CurrentDir.SlerpTowards(Dir, Delta);

		Turret.Mesh_Holder.SetWorldRotation(FRotator::MakeFromZX(InitialUpDir, CurrentDir));

		// Ease rotation for gun
		FVector CurrentGunDir = Turret.Mesh_Turret.WorldRotation.Vector().GetSafeNormal();
		const float HolderRotationSpeed = 10;
		float HolderDelta = HolderRotationSpeed * DeltaTime;	
		FVector RightVector = Turret.Mesh_Turret.GetRightVector();
		Dir = Dir.RotateAngleAxis(-45, RightVector);
		CurrentGunDir = CurrentGunDir.SlerpTowards(Dir, HolderDelta);
		Turret.Mesh_Turret.SetWorldRotation(FRotator::MakeFromYX(RightVector, CurrentGunDir));
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
			Turret.Mesh_Holder.SetWorldRotation(FRotator::MakeFromZX(InitialUpDir, Dir));

			FVector RightVector = Turret.Mesh_Holder.GetRightVector();
			Turret.Mesh_Turret.SetWorldRotation(FRotator::MakeFromYX(RightVector, Dir));
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
