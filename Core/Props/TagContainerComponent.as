
UCLASS(HideCategories = "Shape Lighting Navigation Physics Activation Cooking Input Mobile HLOD AssetUserData VirtualTexture Physics")
class UTagContainerComponent : USphereComponent
{
    default bIsEditorOnly = true;
    default bHiddenInGame = true;
    default bVisible = false;
	default SetCollisionEnabled(ECollisionEnabled::NoCollision);
};