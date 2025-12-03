/**
 * Creates and attaches a static mesh to the player when activated.
 */
class UIceBowEquipCapability : UHazePlayerCapability
{
    default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
   	default DebugCategory = IceBow::DebugCategory;
    
    default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(IceBow::IceBowTag);

	default CapabilityTags.Add(BlockedWhileIn::Crouch);

	UIceBowPlayerComponent IceBowPlayerComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        IceBowPlayerComp = UIceBowPlayerComponent::Get(Player);

        IceBowPlayerComp.IceBowMeshComponent = UStaticMeshComponent::Create(Player, IceBow::BowComponentName);
        IceBowPlayerComp.IceBowMeshComponent.StaticMesh = IceBowPlayerComp.BowSettings.IceBowMesh;
        IceBowPlayerComp.IceBowMeshComponent.CollisionEnabled = ECollisionEnabled::NoCollision;
        IceBowPlayerComp.IceBowMeshComponent.SetCollisionProfileName(n"NoCollision");
        IceBowPlayerComp.IceBowMeshComponent.SetGenerateOverlapEvents(false);
        IceBowPlayerComp.IceBowMeshComponent.AddTag(ComponentTags::HideOnCameraOverlap);

        IceBowPlayerComp.IceBowMeshComponent.AttachToComponent(Player.Mesh, IceBow::BowAttachSocket);
        IceBowPlayerComp.IceBowMeshComponent.SetRelativeLocationAndRotation(FVector(0.0, 0.0, 0.0), FRotator(0.0, 90.0, 90.0));

        IceBowPlayerComp.IceBowMeshComponent.AddComponentVisualsBlocker(this);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(!IceBowPlayerComp.bIsAimingIceBow)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(IceBowPlayerComp.GetIsUsingIceBow())
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
        IceBowPlayerComp.IceBowMeshComponent.RemoveComponentVisualsBlocker(this);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        IceBowPlayerComp.IceBowMeshComponent.AddComponentVisualsBlocker(this);
    }
}