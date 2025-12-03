struct FDentistToothGroundPoundRecoverDeactivateParams
{
	bool bInterrupted = false;
}

class UDentistToothGroundPoundRecoverCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::Tags::GroundPound);
	default CapabilityTags.Add(Dentist::Tags::CancelOnRagdoll);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothGroundPoundComponent GroundPoundComp;

	UPlayerMovementComponent MoveComp;

	bool bIsBlockingDash = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		GroundPoundComp = UDentistToothGroundPoundComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GroundPoundComp.DesiredState != EDentistToothGroundPoundState::Recover)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDentistToothGroundPoundRecoverDeactivateParams& Params) const
	{
		if(GroundPoundComp.CurrentState != EDentistToothGroundPoundState::Recover)
		{
			Params.bInterrupted = true;
			return true;
		}

		if(PlayerComp.HasSetMeshRotationThisFrame())
		{
			Params.bInterrupted = true;
			return true;
		}

		float RecoverDuration = GroundPoundComp.Settings.RecoverDuration;
		if(!MoveComp.MovementInput.IsNearlyZero())
			RecoverDuration = GroundPoundComp.Settings.RecoverIfInputDuration;

		if(ActiveDuration > RecoverDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GroundPoundComp.CurrentState = EDentistToothGroundPoundState::Recover;

		Player.BlockCapabilities(Dentist::Tags::Dash, this);
		bIsBlockingDash = true;

		UDentistToothEventHandler::Trigger_OnStartGroundPoundRecovery(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDentistToothGroundPoundRecoverDeactivateParams Params)
	{
		if(!Params.bInterrupted)
		{
			GroundPoundComp.DesiredState = EDentistToothGroundPoundState::None;
			GroundPoundComp.CurrentState = EDentistToothGroundPoundState::None;
		}

		if(bIsBlockingDash)
		{
			Player.UnblockCapabilities(Dentist::Tags::Dash, this);
			bIsBlockingDash = false;
		}

		UDentistToothEventHandler::Trigger_OnStopGroundPoundRecovery(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bIsBlockingDash && ActiveDuration > GroundPoundComp.Settings.AnticipationBlockDashDuration)
		{
			Player.UnblockCapabilities(Dentist::Tags::Dash, this);
			bIsBlockingDash = false;
		}

		if(PlayerComp.HasSetMeshRotationThisFrame())
			return;

		float Alpha = Math::Saturate(ActiveDuration / GroundPoundComp.Settings.RecoverDuration);

		const float AngleAlpha = GroundPoundComp.Settings.RecoverAngleAlphaCurve.GetFloatValue(Alpha);
		FQuat SpinRotation = FQuat(FVector::RightVector, Math::DegreesToRadians(AngleAlpha * -180));
		SpinRotation = Player.ActorTransform.TransformRotation(SpinRotation);

		if(Dentist::GroundPound::bApplyRotation)
			PlayerComp.SetMeshWorldRotation(SpinRotation, this, -1, DeltaTime);
	}
};