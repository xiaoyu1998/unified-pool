import { expect } from "chai";
import { deployFixture } from "../../utils/fixture";

describe("Config", () => {
  let fixture;
  let user0, user1, user2;
  let config, dataStore, roleStore;

  beforeEach(async () => {
      fixture = await deployFixture();
      ({ config, dataStore, roleStore } = fixture.contracts);

  });

  it("allows required keys", async () => {

  });
});