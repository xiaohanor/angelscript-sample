namespace MedallionTags
{
	const FName MedallionTag = n"Medallion";

	const FName MedallionHighfiveHoldInstigator = n"MedallionHighfiveHoldInstigator";
	const FName MedallionGloryKillButtonmashInstigator = n"MedallionGloryKillButtonmashInstigator";

	const FName MedallionSidescrollerTag = n"MedallionSidescroller";
	const FName MedallionCoopFlying = n"MedallionCoopFlying";
	const FName MedallionCoopFlyingActive = n"MedallionCoopFlyingActive";
	const FName MedallionGloryKill = n"MedallionGloryKill";

	const FName MedallionScreenMerged = n"MedallionScreenMerged";
}

asset MedallionPlayerSheet of UHazeCapabilitySheet
{
	// whole medallion phase
	Capabilities.Add(UMedallionPlayerWholePhaseCapability);
	Capabilities.Add(UMedallionPlayerTetherCapability);
	Capabilities.Add(UMedallionPlayerTetherToHydraCapability);
	Capabilities.Add(UMedallionPlayerBlockContextualsCapability);

	Sheets.Add(MedallionPlayerSidescrollerSheet);
	Sheets.Add(MedallionPlayerMergeSheet);
	Sheets.Add(MedallionPlayerHighfiveSheet);
	Sheets.Add(MedallionPlayerFlyingSheet);
	Sheets.Add(MedallionPlayerGloryKillSheet);
}

asset MedallionPlayerSidescrollerSheet of UHazeCapabilitySheet
{
	// sidescroller
	Capabilities.Add(UMedallionPlayerSidescrollerCapability);
	Capabilities.Add(UMedallionPlayerSidescrollerPerspectiveCapability);
	Capabilities.Add(UMedallionPlayerSidescrollerCameraFocusCapability);
}

asset MedallionPlayerMergeSheet of UHazeCapabilitySheet
{
	//merge
	Capabilities.Add(UMedallionPlayerMergePhaseCapability);
	Capabilities.Add(UMedallionPlayerMergeScreenCapability);
	Capabilities.Add(UMedallionPlayerMergingZoomCapability);
	Capabilities.Add(UMedallionPlayerMergingRespawnPointCapability);
	Capabilities.Add(UMedallionPlayerMergingCompanionCirclingCapability);
	Capabilities.Add(UMedallionPlayerSidescrollerCameraProjectionOffsetCapability);
	Capabilities.Add(UMedallionPlayerMergeHealthOverrideCapability);
	//Capabilities.Add(UMedallionPlayerMergeTimeDilationCapability);	
}

asset MedallionPlayerHighfiveSheet of UHazeCapabilitySheet
{
	// high five
	Components.Add(UMedallionPlayerMergeHighfiveJumpComponent);

	Capabilities.Add(UMedallionPlayerMergingHighfiveHoldCapability);
	Capabilities.Add(UMedallionPlayerMergingHighfiveJumpMovementCapability);

	Capabilities.Add(UMedallionPlayerMergeHighfiveAllowstartCapability);
	Capabilities.Add(UMedallionPlayerMergeHighfiveActiveCapability);
	Capabilities.Add(UMedallionPlayerMergeHighfiveTimedilationCapability);
	Capabilities.Add(UMedallionPlayerMergeHighfiveSuccessOrFailCapability);
	Capabilities.Add(UMedallionPlayerMergeHighfiveResetCapability);
}

asset MedallionPlayerFlyingSheet of UHazeCapabilitySheet
{
	// flying
	Components.Add(UMedallionPlayerFlyingMovementComponent);
	Capabilities.Add(UMedallionPlayerTriggerFlyingCapability);
	Capabilities.Add(UMedallionPlayerFlyingCameraCapability);
	Capabilities.Add(UMedallionPlayerFlyingMovementCapability);
	Capabilities.Add(UMedallionPlayerFlyingDashCapability);
	Capabilities.Add(UMedallionPlayerFlyingKnockedCapability);
	Capabilities.Add(UMedallionPlayerFlyingInputCapability);
	Capabilities.Add(UMedallionPlayerFlyingFeedbackCapability);
	Capabilities.Add(UMedallionPlayerFlyingHideMiniCompanionsCapability);
	//Capabilities.Add(UMedallionPlayerFlyingCheckHydrasCapability);
}

asset MedallionPlayerGloryKillSheet of UHazeCapabilitySheet
{
	// glory kill
	Components.Add(UMedallionPlayerGloryKillComponent);
	Capabilities.Add(UMedallionPlayerGloryKillButtonmashCapability);
	Capabilities.Add(UMedallionPlayerGloryKillCameraCapability);
	// states in order
	Capabilities.Add(UMedallionPlayerGloryKill0SelectHydraCapability);
	Capabilities.Add(UMedallionPlayerGloryKill1EnterMovementCapability);
	Capabilities.Add(UMedallionPlayerGloryKill2EnterSequenceCapability);
	Capabilities.Add(UMedallionPlayerGloryKill3StrangleMovementCapability);
	Capabilities.Add(UMedallionPlayerGloryKill3StrangleSuccessCapability);
	Capabilities.Add(UMedallionPlayerGloryKill4ExecuteSequenceCapability);
	Capabilities.Add(UMedallionPlayerGloryKill5ReturnMovementCapability);
	Capabilities.Add(UMedallionPlayerGloryKillReturnCameraCapability);

	Capabilities.Add(UMedallionPlayerGloryKillDebugDrawCapability);
	Capabilities.Add(UMedallionPlayerGloryKillDebugHideOtherHydrasCapability);
}
