/* This component should not be interacted with directly. It should be controlled by a force field collision component or spherical force field procedural collision generation component, etc. */
UCLASS(NotBlueprintable, NotPlaceable)
class UIslandRedBlueForceFieldProceduralCollisionComponent : UProceduralMeshComponent
{
	//default SetCollisionProfileName(n"BlockAllDynamic");
	default SetCollisionEnabled(ECollisionEnabled::PhysicsOnly);
	default SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default SetCollisionResponseToChannel(ECollisionChannel::ECC_PhysicsBody, ECollisionResponse::ECR_Block);
}

struct FIslandRedBlueForceFieldProceduralCollisionData
{
	TArray<FVector> Vertices;
	TArray<int> Triangles;
	TArray<FVector> Normals;
	TArray<FVector2D> UV;
	TArray<FLinearColor> VertexColors;
	TArray<FProcMeshTangent> Tangents;
}