
UCLASS(Abstract)
class AAIslandFloatotronSidescroller : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"IslandFloatotronSidescrollerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandSidescrollerFlyingMovementCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"IslandForceFieldCapability");
	
	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactCounterResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent, Attach = "MeshOffsetComponent")
	UIslandForceFieldComponent ForceFieldComp;	

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightAttach")
	UBasicAIProjectileLauncherComponent LauncherComp;

	// From ABasicAIFlyingCharacter
	UPROPERTY(DefaultComponent)
	UBasicAIFlightComponent FlightComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		RespawnComp.OnRespawn.AddUFunction(FlightComp, n"Reset");
		this.JoinTeam(IslandFloatotronSidescrollerTags::IslandFloatotronTeam);
	}

}


namespace IslandFloatotronSidescrollerTags
{
	const FName IslandFloatotronTeam = n"IslandFloatotronTeam";
}