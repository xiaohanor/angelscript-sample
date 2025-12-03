/**
 * 
 */
class UWindJavelinSpawnCapability : UHazePlayerCapability
{
    default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
   	default DebugCategory = WindJavelin::DebugCategory;

    default CapabilityTags.Add(CapabilityTags::GameplayAction);
    default CapabilityTags.Add(WindJavelin::WindJavelinTag);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Crouch);

	UWindJavelinPlayerComponent PlayerComp;

	// needs to activate before the throwing capability
	default TickGroupOrder = 100;
	default TickGroup = EHazeTickGroup::Gameplay;

    int SpawnedWindJavelinCounter = 0;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = UWindJavelinPlayerComponent::Get(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if (!PlayerComp.bSpawn)
            return false;

        if (PlayerComp.WindJavelin != nullptr)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        return true;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
        UWindJavelinEventHandler::Trigger_Spawned(Player);

        UClass JavelinClass = PlayerComp.WindJavelinClass;
        FTransform SocketTransform = Player.Mesh.GetSocketTransform(WindJavelin::JavelinAttachSocket);
        FVector Location = SocketTransform.Location;
        FQuat Rotation = SocketTransform.Rotation;
        Location -= Rotation * Settings.HandHoldRelativeLocation;
        PlayerComp.WindJavelin = Cast<AWindJavelin>(SpawnActor(JavelinClass, Location, Rotation.Rotator(), NAME_None, true));
        PlayerComp.WindJavelin.AttachToComponent(Player.Mesh, WindJavelin::JavelinAttachSocket, EAttachmentRule::KeepWorld);
        PlayerComp.WindJavelin.MakeNetworked(this, SpawnedWindJavelinCounter);
		SpawnedWindJavelinCounter++;
        FinishSpawningActor(PlayerComp.WindJavelin);

        UWindJavelinProjectileEventHandler::Trigger_Spawned(PlayerComp.WindJavelin);

        PlayerComp.bSpawn = false;
    }

    UWindJavelinSettings GetSettings() const property
    {
        return PlayerComp.Settings;
    }
}