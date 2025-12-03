struct FCentipedeSwingSettings
{
	// Even if player releases bite action, this time needs to pass before
	// centipede actually releases mandible. Used to avoid network spamming.
	const float MinimumBiteDuration = 0.2;
}