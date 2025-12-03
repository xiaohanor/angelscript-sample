class APlayerCharacter : AHazePlayerCharacter
{
	default RootComponent.bAbsoluteScale = true;
	default CapsuleComponent.CollisionProfileName = n"PlayerCharacter";

	default Mesh.ReceivesDecals = false;
	default Mesh.bUseShadowProxyMesh = true;
	default Mesh.ShadowProxyMinimumLOD = 3;

	UPROPERTY(DefaultComponent)
	UHazeInputComponent InputComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPosition;
	default SyncedPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Player;
	default SyncedPosition.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default SyncedPosition.SleepAfterIdleTime = MAX_flt;
	default SyncedPosition.SetMaintainControlWorldUpDefaultValue(true);

	UPROPERTY(DefaultComponent)
	UCameraUserComponent CameraUserComponent;
	default CameraUserComponent.DefaultBlendSettings = UCameraDefaultBlend;
	default CameraUserComponent.bAllowEditorRerunFrames = true;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedCameraComponent CameraSyncedRotation;
	default CameraSyncedRotation.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default CameraSyncedRotation.SleepAfterIdleTime = MAX_flt;

	UPROPERTY(DefaultComponent, Attach = CameraOffsetComponent)
	USpringArmCamera Camera;
	// Hide the default overrides on the player
	default Camera.bHasCameraSettings = false;
	default Camera.bHasSpringArmSettings = false;
	default Camera.bHasClampSettings = false;

	UPROPERTY(DefaultComponent)
	UCameraFollowMovementFollowDataComponent CameraFollowMovementComponent;

	UPROPERTY(DefaultComponent)
	UHazePlayerForceFeedbackComponent ForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UPlayerRespawnComponent RespawnComponent;

	UPROPERTY(DefaultComponent)
	UPlayerHealthComponent HealthComponent;

	UPROPERTY(DefaultComponent)
	UOutlineViewerComponent OutlinesComponent;

	UPROPERTY(DefaultComponent)
	UStencilEffectViewerComponent StencilEffectComponent;

	UPROPERTY(DefaultComponent)
	UDynamicWaterEffectDecalComponent WaterRipples;
	default WaterRipples.SetRelativeScale3D(FVector(0.25, 0.25, 0.25));
	default WaterRipples.Strength = 0.5;
	default WaterRipples.bOnlyActiveInSurfaceVolumes = true;
	
	UPROPERTY(DefaultComponent)
	UPostProcessingComponent PostProcessingComponent;
	default PostProcessingComponent.OutlinesComponent = OutlinesComponent;

	UPROPERTY(DefaultComponent)
	UHazeVoxCharacterTemplateComponent VoxCharacterTemplateComponent;

	UPROPERTY(DefaultComponent)
	UHazePlayerGamepadLightComponent GamepadLightComponent;

	UPROPERTY(DefaultComponent)
	UPlayerVFXSettingsComponent VFXSettings;

	default CapabilityComponent.DefaultCapabilities.Add(n"CameraControlCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"CameraControlReplicationCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"CameraUpdateCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"CameraHideOverlappersCapability");	
	default CapabilityComponent.DefaultCapabilities.Add(n"CameraModifierCapability");	
	default CapabilityComponent.DefaultCapabilities.Add(n"CameraImpulseCapability");	
	default CapabilityComponent.DefaultCapabilities.Add(n"CameraMatchOthersCutsceneRotationCapability");	
	//default CapabilityComponent.DefaultCapabilities.Add(n"CameraNonControlledCapability");	
	default CapabilityComponent.DefaultCapabilities.Add(n"CameraNonControlledTransitionCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"CameraVolumePlayerConditionCapability");
#if TEST
	default CapabilityComponent.DefaultCapabilities.Add(n"DebugCameraCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"CameraUserDebugLoggerCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"DebugAnimationInspectionCameraCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerGlobalTemporalLogCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerDebugWhoIsWhoCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"ForceFeedbackDevTogglesCapability");
#endif
	
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerVisibilityCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerSubsurfaceEnablementCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerCollisionCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"WorldRumbleUpdateCapability");

	// * Health capabilities
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerRespawnMashCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerRespawnCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerDeathCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerHealthRegenerationCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerHealthDisplayCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerGameOverCapability");

	// Audio
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerDefaultListenerCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerCutsceneListenerCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerFullscreenListenerCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerSidescrollerListenerCapability");

	// PS5 Gamepad
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerGamepadLightCapability");

	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerDefaultRtpcCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerSetPanningCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerAudioReflectionTraceCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerAudioReflectionTraceStaticCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerAudioReflectionTraceFullscreenCapability");

	#if TEST
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerDebugCameraListenerCapability");
	#endif

	// Vox
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerPauseVoxOnDeathCapability");

	#if EDITOR
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerAudioDebugNetworkCapability");
	#endif

	// Gameplay Core
	default CapabilityComponent.DefaultCapabilities.Add(n"ButtonMashCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"StickSpinCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"StickWiggleCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"AimingGamepadInputCapability2D");
	default CapabilityComponent.DefaultCapabilities.Add(n"AimingMouseInputCapability2D");

	// Animation
	default CapabilityComponent.DefaultCapabilities.Add(n"AnimPlayerLookAtCapabillity");
#if TEST
	default CapabilityComponent.DefaultCapabilities.Add(n"AnimDebugDrawCapsuleCapabillity");
#endif

	default CapabilityComponent.DefaultCapabilities.Add(n"FindOtherPlayerCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerSyncLocationMeshOffsetCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"PlayerAdditiveHitReactionCapability");

	// AI
#if TEST
	default CapabilityComponent.DefaultCapabilities.Add(n"GentlemanLogCapability");
#endif

	UPROPERTY(DefaultComponent)
	UHazeDevInputComponent DevInputComponent;

	UPROPERTY(DefaultComponent)
	UHazeDevInputLockComponent DevInputLockComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TemporalLog::RegisterExtender(this, "Input", n"TemporalLogInputExtender");
	}

	UFUNCTION(BlueprintOverride)
	private FVector GetFocusLocation() const
	{
		return PlayerFocus::GetPlayerFocusLocation(this);
	}
};